import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/led_model.dart';

class TimerService {
  final DateFormat timeFormat = DateFormat("HH:mm");
  final DatabaseReference dbR = FirebaseDatabase.instance.ref();

  Future<void> saveTimers(List<LedModel> ledModel) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> schedulesJson = ledModel.map((schedule) {
      return jsonEncode(schedule.toJson());
    }).toList();
    await prefs.setStringList('timerSchedules', schedulesJson);
  }

  Future<List<LedModel>> loadSavedTimers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? schedulesJson = prefs.getStringList('timerSchedules');
    if (schedulesJson != null) {
      return schedulesJson.map((scheduleJson) {
        return LedModel.fromJson(jsonDecode(scheduleJson));
      }).toList();
    }
    return [];
  }

  void checkTimers(
      List<LedModel> LedModels, Function updateLedStatus) {
    final now = DateTime.now();
    String currentDay = DateFormat('EEE').format(now);
    String currentTime = timeFormat.format(now);

    for (var schedule in LedModels) {
      if (!schedule.isActive) continue;

      String scheduleTime = timeFormat.format(schedule.time);
      bool isToday = schedule.repeatDays.isEmpty;

      if (isToday || schedule.repeatDays.contains(currentDay)) {
        if (scheduleTime == currentTime) {
          if (schedule.isOnSetting) {
            if (schedule.selectedLEDs[0]) {
              dbR.child("Light").update({"Led1": true});
              updateLedStatus(1, true);
            }
            if (schedule.selectedLEDs[1]) {
              dbR.child("Light").update({"Led2": true});
              updateLedStatus(2, true);
            }
          } else {
            if (schedule.selectedLEDs[0]) {
              dbR.child("Light").update({"Led1": false});
              updateLedStatus(1, false);
            }
            if (schedule.selectedLEDs[1]) {
              dbR.child("Light").update({"Led2": false});
              updateLedStatus(2, false);
            }
          }
          if (isToday) {
            schedule.isActive = false;
          }
        }
      }
    }
  }
}
