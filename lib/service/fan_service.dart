import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/fan_model.dart';

class FanService {
  final DateFormat timeFormat = DateFormat("HH:mm");
  final DatabaseReference dbR = FirebaseDatabase.instance.ref();

  // Hàm để lưu lịch hẹn giờ vào SharedPreferences
  Future<void> saveTimers(List<FanSchedule> fanSchedules) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> schedulesJson = fanSchedules.map((schedule) {
      return jsonEncode(schedule.toJson());
    }).toList();
    await prefs.setStringList('fanSchedules', schedulesJson);
  }

  // Hàm để tải lịch hẹn giờ từ SharedPreferences
  Future<List<FanSchedule>> loadSavedTimers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? schedulesJson = prefs.getStringList('fanSchedules');
    if (schedulesJson != null) {
      return schedulesJson.map((scheduleJson) {
        return FanSchedule.fromJson(jsonDecode(scheduleJson));
      }).toList();
    }
    return [];
  }

  // Hàm kiểm tra và thực hiện lịch hẹn giờ
  void checkTimers(
      List<FanSchedule> fanSchedules, Function(bool) updateFanStatus) {
    final now = DateTime.now();
    final String currentDay = DateFormat('EEE').format(now);
    final String currentTime = timeFormat.format(now);

    for (var schedule in fanSchedules) {
      if (!schedule.isActive) continue;

      final String scheduleTime = timeFormat.format(schedule.time);
      final bool isToday = schedule.repeatDays.isEmpty || schedule.repeatDays.contains(currentDay);

      if (isToday && scheduleTime == currentTime) {
        if (schedule.isOnSetting) {
          dbR.child("Fan").update({"fan": true});
          updateFanStatus(true);
          print("Fan is turned on at $currentTime on $currentDay");
        } else {
          dbR.child("Fan").update({"fan": false});
          updateFanStatus(false);
          print("Fan is turned off at $currentTime on $currentDay");
        }

        // Sau khi thực hiện lịch, vô hiệu hóa lịch
        schedule.isActive = false;
        saveTimers(fanSchedules); // Lưu lại trạng thái của lịch vào SharedPreferences
      }
    }
  }
}
