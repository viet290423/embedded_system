import 'dart:async';
import 'package:embedded_system/provider/led_provider.dart';
import 'package:embedded_system/service/led_service.dart';
import 'package:flutter/material.dart';
import 'package:embedded_system/model/led_model.dart';
import 'package:embedded_system/widget/controltile_widget.dart';
import 'package:embedded_system/set_time/timer_page.dart';
import 'package:embedded_system/widget/card_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Thư viện mới thêm vào
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LedPage extends StatefulWidget {
  const LedPage({super.key});

  @override
  State<LedPage> createState() => _LedPageState();
}

class _LedPageState extends State<LedPage> {
  bool led1status = false;
  bool led2status = false;
  List<LedModel> timerSchedules = [];
  Timer? timer;
  final TimerService timerService = TimerService();

  @override
  void initState() {
    context.read<TimerProvider>().initializeNotifications(context);
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
    super.initState();
    // context.read<alarmprovider>().GetData();
    _loadSavedTimers();
    _listenToLedStatus();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkTimers();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _listenToLedStatus() {
    timerService.dbR.child("Light/Led1").onValue.listen((event) {
      final newLed1Status = event.snapshot.value as bool;
      setState(() {
        led1status = newLed1Status;
      });
    });

    timerService.dbR.child("Light/Led2").onValue.listen((event) {
      final newLed2Status = event.snapshot.value as bool;
      setState(() {
        led2status = newLed2Status;
      });
    });
  }

  Future<void> _loadSavedTimers() async {
    timerSchedules = await timerService.loadSavedTimers();
    setState(() {});
  }

  void _checkTimers() {
    timerService.checkTimers(timerSchedules, (led, status) {
      setState(() {
        if (led == 1) {
          led1status = status;
        } else if (led == 2) {
          led2status = status;
        }
      });
    });
  }

  void addTimer(DateTime time, List<String> repeatDays, List<bool> selectedLEDs,
      bool isOnSetting) {
    setState(() {
      timerSchedules
          .add(LedModel(time, repeatDays, selectedLEDs, isOnSetting));
    });
    timerService.saveTimers(timerSchedules);
  }

  void deleteTimer(int index) {
    setState(() {
      timerSchedules.removeAt(index);
    });
    timerService.saveTimers(timerSchedules); // Lưu lại danh sách đã thay đổi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.light),
            SizedBox(
              width: 10,
            ),
            Text("Led Control")
          ],
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
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
                  child: CardWidget(title: "Control led", children: [
                    // Điều khiển LED 1
                    ControlTileWidget(
                        title: "LED 1",
                        status: led1status,
                        onChanged: (value) {
                          timerService.dbR
                              .child("Light")
                              .update({"Led1": value});
                          setState(() {
                            led1status = value;
                          });
                        },
                        color: Colors.redAccent),

                    // Điều khiển LED 2
                    ControlTileWidget(
                        title: "LED 2",
                        status: led2status,
                        onChanged: (value) {
                          timerService.dbR
                              .child("Light")
                              .update({"Led2": value});
                          setState(() {
                            led2status = value;
                          });
                        },
                        color: Colors.green),

                    // Điều khiển cả 2 đèn
                    ControlTileWidget(
                        title: "ALL",
                        status: led1status & led2status,
                        onChanged: (value) {
                          timerService.dbR
                              .child("Light")
                              .update({"Led1": value});
                          timerService.dbR
                              .child("Light")
                              .update({"Led2": value});
                          setState(() {
                            led1status = value;
                            led2status = value;
                          });
                        },
                        color: Colors.orange),
                  ]),
                ),
                const SizedBox(
                  width: 10,
                ),
                CardWidget(
                  title: "Set scheduled",
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TimerSettingPage(
                            isOnSetting: true,
                            onSave: (time, repeatDays, selectedLEDs) {
                              addTimer(time, repeatDays, selectedLEDs, true);
                            },
                          ),
                        ));
                      },
                      child: const Text("Set On Timer",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TimerSettingPage(
                              isOnSetting: false,
                              onSave: (time, repeatDays, selectedLEDs) {
                                addTimer(time, repeatDays, selectedLEDs, false);
                              }),
                        ));
                      },
                      child: const Text("Set Off Timer",
                          style: TextStyle(color: Colors.white)),
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
                    child: Slidable(
                      key: ValueKey(index),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              deleteTimer(index);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                            borderRadius: BorderRadius.circular(20),
                            flex: 1,
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 3,
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          title: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: schedule.isOnSetting
                                      ? "Set On: "
                                      : "Set Off: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      DateFormat('HH:mm').format(schedule.time),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "Repeat: ${schedule.repeatDays.isEmpty ? 'None' : schedule.repeatDays.join(", ")}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
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
