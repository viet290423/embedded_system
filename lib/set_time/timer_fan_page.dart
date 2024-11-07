import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimerFanPage extends StatefulWidget {
  final Function(DateTime, List<String>) onSave; // Hàm callback để lưu giờ
  final bool isOnSetting; // Đang đặt Set On hay Set Off

  const TimerFanPage(
      {super.key, required this.onSave, required this.isOnSetting});

  @override
  State<TimerFanPage> createState() => _TimerFanPageState();
}

class _TimerFanPageState extends State<TimerFanPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isOnSetting ? "Set On Timer" : "Set Off Timer"),
        forceMaterialTransparency: true,
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

          // Nút lưu cài đặt
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              onPressed: () {
                widget.onSave(
                  selectedTime,
                  daysOfWeek
                      .asMap()
                      .entries
                      .where((entry) => repeatDays[entry.key])
                      .map((entry) => entry.value)
                      .toList(),
                );
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
