import 'dart:math';

import 'package:embedded_system/provider/timer_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimerSettingPage extends StatefulWidget {
  final Function(DateTime, List<String>, List<bool>)
      onSave; // Hàm callback để lưu giờ
  final bool isOnSetting; // Đang đặt Set On hay Set Off

  const TimerSettingPage(
      {super.key, required this.onSave, required this.isOnSetting});

  @override
  State<TimerSettingPage> createState() => _TimerSettingPageState();
}

class _TimerSettingPageState extends State<TimerSettingPage> {
  late TextEditingController controller;
  DateTime selectedTime = DateTime.now(); // Thời gian hẹn giờ
  List<String> daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List<bool> repeatDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ]; // Trạng thái lặp lại theo thứ
  List<bool> selectedLEDs = [false, false]; // Trạng thái chọn LED 1 và LED 2

  @override
  void initState() {
    controller = TextEditingController();
    // context.read<TimerProvider>().getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isOnSetting ? "Set On Timer" : "Set Off Timer"),
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Picker chọn giờ
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

          // Chọn Repeat (Ngày lặp lại)
          ListTile(
            title: const Row(
              children: [
                Text(
                  "Repeat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  CupertinoIcons.arrow_down_circle_fill,
                  size: 20,
                )
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

          // Chọn đèn
          ListTile(
            title: const Text(
              "Select LED",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: const Text("Choose which LED to control"),
            trailing: Wrap(
              spacing: 10.0,
              children: [
                ChoiceChip(
                  backgroundColor: Colors.white,
                  selectedColor: Colors.black,
                  label: Text(
                    "LED 1",
                    style: TextStyle(
                      color: selectedLEDs[0] ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: selectedLEDs[0],
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLEDs[0] = selected;
                    });
                  },
                  checkmarkColor: Colors.white,
                ),
                ChoiceChip(
                  backgroundColor: Colors.white,
                  selectedColor: Colors.black,
                  label: Text(
                    "LED 2",
                    style: TextStyle(
                      color: selectedLEDs[1] ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: selectedLEDs[1],
                  onSelected: (bool selected) {
                    setState(() {
                      selectedLEDs[1] = selected;
                    });
                  },
                  checkmarkColor: Colors.white,
                ),
              ],
            ),
          ),
          const Divider(),

          // Nút lưu cài đặt
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: () {
                if (selectedLEDs.any((element) => element)) {
                  Random random = Random();
                  int randomNumber =
                      random.nextInt(100); // Tạo số ngẫu nhiên để dùng làm ID

                  widget.onSave(
                    selectedTime,
                    daysOfWeek
                        .asMap()
                        .entries
                        .where((entry) => repeatDays[entry.key])
                        .map((entry) => entry.value)
                        .toList(),
                    selectedLEDs,
                  );

                  context.read<TimerProvider>().addSchedule(
                        selectedTime,
                        daysOfWeek
                            .asMap()
                            .entries
                            .where((entry) => repeatDays[entry.key])
                            .map((entry) => entry.value)
                            .toList(),
                        selectedLEDs,
                        widget.isOnSetting,
                      );

                  context.read<TimerProvider>().saveData();

                  context
                      .read<TimerProvider>()
                      .scheduleNotification(selectedTime, randomNumber);

                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select at least one LED.")),
                  );
                }
              },
              child: const Text(
                "Save Timer",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
