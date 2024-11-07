import 'dart:math';

import 'package:embedded_system/provider/fan_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimerFanPage extends StatefulWidget {
  final Function(DateTime, List<String>) onSave; // Callback to save the time
  final bool isOnSetting; // Determines whether this is for turning the fan on or off

  const TimerFanPage({super.key, required this.onSave, required this.isOnSetting});

  @override
  State<TimerFanPage> createState() => _TimerFanPageState();
}

class _TimerFanPageState extends State<TimerFanPage> {
  DateTime selectedTime = DateTime.now(); // Selected time for scheduling
  List<String> daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List<bool> repeatDays = [false, false, false, false, false, false, false]; // Repeat days status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isOnSetting ? "Set Fan On Timer" : "Set Fan Off Timer"),
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Time Picker
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: selectedTime,
              onDateTimeChanged: (DateTime newTime) {
                setState(() {
                  selectedTime = newTime;
                });
              },
            ),
          ),
          const SizedBox(height: 20),

          // Repeat Selection
          ListTile(
            title: const Row(
              children: [
                Text(
                  "Repeat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                SizedBox(width: 5),
                Icon(
                  CupertinoIcons.arrow_down_circle_fill,
                  size: 20,
                ),
              ],
            ),
            subtitle: Text(
              repeatDays
                  .asMap()
                  .entries
                  .where((e) => e.value)
                  .map((e) => daysOfWeek[e.key])
                  .join(", "),
              style: TextStyle(color: Colors.black54),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Repeat on"),
                  content: StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(7, (index) {
                          return CheckboxListTile(
                            title: Text(daysOfWeek[index]),
                            value: repeatDays[index],
                            onChanged: (value) {
                              setStateDialog(() {
                                repeatDays[index] = value ?? false;
                              });
                            },
                          );
                        }),
                      );
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(),

          // Save Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: () {
                Random random = Random();
                int randomNumber = random.nextInt(100); // Random ID for scheduling

                // Call the onSave callback with the selected time and repeat days
                widget.onSave(
                  selectedTime,
                  daysOfWeek
                      .asMap()
                      .entries
                      .where((entry) => repeatDays[entry.key])
                      .map((entry) => entry.value)
                      .toList(),
                );

                // Save the schedule and set up notifications
                context.read<FanProvider>().addFanSchedule(
                  selectedTime,
                  daysOfWeek
                      .asMap()
                      .entries
                      .where((entry) => repeatDays[entry.key])
                      .map((entry) => entry.value)
                      .toList(),
                  widget.isOnSetting,
                );

                context.read<FanProvider>().saveFanData();

                // Schedule the notification
                context.read<FanProvider>().scheduleFanNotification(
                  selectedTime,
                  randomNumber,
                );

                // Close the page
                Navigator.of(context).pop();
              },
              child: const Text(
                "Save Timer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
