import 'dart:async';
import 'package:embedded_system/model/fan_model.dart';
import 'package:embedded_system/provider/fan_provider.dart';
import 'package:embedded_system/provider/timer_provider.dart';
import 'package:embedded_system/service/fan_service.dart';
import 'package:embedded_system/widget/controltile_widget.dart';
import 'package:embedded_system/set_time/timer_fan_page.dart';
import 'package:embedded_system/widget/card_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FanPage extends StatefulWidget {
  const FanPage({super.key});

  @override
  State<FanPage> createState() => _FanPageState();
}

class _FanPageState extends State<FanPage> {
  bool fanStatus = false; 
  List<FanSchedule> timerSchedules = []; 
  Timer? timer; 
  final FanService fanService = FanService(); // FanService handles fan-specific timer functions

  @override
  void initState() {
    super.initState();
    context.read<FanProvider>().initializeNotifications(context); // Initialize notifications
    _loadSavedTimers(); 
    _listenToFanStatus();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTimers();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _listenToFanStatus() {
    fanService.dbR.child("Fan/fan").onValue.listen((event) {
      final newFanStatus = event.snapshot.value as bool;
      setState(() {
        fanStatus = newFanStatus;
      });
    });
  }

  Future<void> _loadSavedTimers() async {
    timerSchedules = await fanService.loadSavedTimers();
    setState(() {});
  }

  void _checkTimers() {
    fanService.checkTimers(timerSchedules, (status) {
      setState(() {
        fanStatus = status;
      });
    });
  }

  void addTimer(DateTime time, List<String> repeatDays, bool isOnSetting) {
    setState(() {
      timerSchedules.add(FanSchedule(time, repeatDays, isOnSetting));
    });
    fanService.saveTimers(timerSchedules);
  }

  void deleteTimer(int index) {
    setState(() {
      timerSchedules.removeAt(index);
    });
    fanService.saveTimers(timerSchedules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.air_outlined),
            SizedBox(width: 10),
            Text("Fan Control")
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CardWidget(
                    title: "Control fan",
                    children: [
                      ControlTileWidget(
                        title: "Fan",
                        status: fanStatus,
                        onChanged: (value) {
                          fanService.dbR.child("Fan").update({"fan": value});
                          setState(() {
                            fanStatus = value;
                          });
                        },
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CardWidget(
                  title: "Set scheduled",
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TimerFanPage(
                            isOnSetting: true,
                            onSave: (time, repeatDays) {
                              addTimer(time, repeatDays, true);
                            },
                          ),
                        ));
                      },
                      child: const Text("Set On Timer", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TimerFanPage(
                            isOnSetting: false,
                            onSave: (time, repeatDays) {
                              addTimer(time, repeatDays, false);
                            },
                          ),
                        ));
                      },
                      child: const Text("Set Off Timer", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: timerSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = timerSchedules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 3,
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        title: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: schedule.isOnSetting ? "Set On: " : "Set Off: ",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                              ),
                              TextSpan(
                                text: DateFormat('HH:mm').format(schedule.time),
                                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            "Repeat: ${schedule.repeatDays.isEmpty ? 'None' : schedule.repeatDays.join(", ")}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),
                        trailing: Switch(
                          value: schedule.isActive,
                          onChanged: (bool value) {
                            setState(() {
                              schedule.isActive = value;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
