import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool led1status = false;
  bool led2status = false;
  DateTime? led1OnTime;
  DateTime? led1OffTime;
  DateTime? led2OnTime;
  DateTime? led2OffTime;
  bool isScheduleActive = false;
  final dbR = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      checkAndControlLEDs();
    });
  }

  void checkAndControlLEDs() {
    if (!isScheduleActive) return;

    final now = DateTime.now();

    if (led1OnTime != null &&
        now.hour == led1OnTime!.hour &&
        now.minute == led1OnTime!.minute) {
      dbR.child("Light").update({"Led1": true});
      setState(() {
        led1status = true;
        led1OnTime = null;
      });
    }
    if (led1OffTime != null &&
        now.hour == led1OffTime!.hour &&
        now.minute == led1OffTime!.minute) {
      dbR.child("Light").update({"Led1": false});
      setState(() {
        led1status = false;
        led1OffTime = null;
      });
    }

    if (led2OnTime != null &&
        now.hour == led2OnTime!.hour &&
        now.minute == led2OnTime!.minute) {
      dbR.child("Light").update({"Led2": true});
      setState(() {
        led2status = true;
        led2OnTime = null;
      });
    }
    if (led2OffTime != null &&
        now.hour == led2OffTime!.hour &&
        now.minute == led2OffTime!.minute) {
      dbR.child("Light").update({"Led2": false});
      setState(() {
        led2status = false;
        led2OffTime = null;
      });
    }
  }

  void setSchedule() {
    if (led1OnTime != null ||
        led1OffTime != null ||
        led2OnTime != null ||
        led2OffTime != null) {
      setState(() {
        isScheduleActive = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule set successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set times for the schedule.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("LED Control - Firebase"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTimeCard(
                "LED 1 Timer",
                [
                  buildCupertinoTimePicker("Turn On Time", led1OnTime,
                      (dateTime) {
                    setState(() {
                      led1OnTime = dateTime;
                    });
                  }),
                  buildCupertinoTimePicker("Turn Off Time", led1OffTime,
                      (dateTime) {
                    setState(() {
                      led1OffTime = dateTime;
                    });
                  }),
                ],
              ),
              buildTimeCard(
                "LED 2 Timer",
                [
                  buildCupertinoTimePicker("Turn On Time", led2OnTime,
                      (dateTime) {
                    setState(() {
                      led2OnTime = dateTime;
                    });
                  }),
                  buildCupertinoTimePicker("Turn Off Time", led2OffTime,
                      (dateTime) {
                    setState(() {
                      led2OffTime = dateTime;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: setSchedule,
                  child: const Text(
                    "Set Schedule",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCupertinoTimePicker(
      String label, DateTime? time, Function(DateTime) onDateTimeChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: time ?? DateTime.now(),
                    onDateTimeChanged: (selectedDateTime) {
                      onDateTimeChanged(selectedDateTime);
                    },
                  ),
                );
              },
            );
          },
          child: Text(
            time == null ? "Select Time" : DateFormat.Hm().format(time),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget buildTimeCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(children: children),
          ],
        ),
      ),
    );
  }
}
