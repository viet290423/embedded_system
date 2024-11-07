import 'dart:convert';
import 'dart:async';
import 'package:embedded_system/main.dart';
import 'package:embedded_system/model/led_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart'; // Nhập Firebase Database
import 'package:timezone/timezone.dart' as tz;

class TimerProvider extends ChangeNotifier {
  late SharedPreferences preferences;

  List<LedModel> scheduleList = [];
  List<String> listOfString = [];
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late BuildContext context;

  final DateFormat timeFormat = DateFormat("HH:mm");
  final DatabaseReference dbR = FirebaseDatabase.instance.ref();

  TimerProvider() {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    preferences = await SharedPreferences.getInstance();
    notifyListeners();
  }

  // Thêm mới lịch trình
  void addSchedule(DateTime time, List<String> repeatDays,
      List<bool> selectedLEDs, bool isOnSetting) {
    scheduleList.add(LedModel(
      time,
      repeatDays,
      selectedLEDs,
      isOnSetting,
    ));
    notifyListeners();
  }

  // Thay đổi trạng thái của lịch trình
  void editScheduleStatus(int index, bool isActive) {
    scheduleList[index].isActive = isActive;
    notifyListeners();
  }

  // Lấy dữ liệu từ SharedPreferences
  Future<void> getData() async {
    preferences = await SharedPreferences.getInstance();
    List<String>? comingList = preferences.getStringList("data");

    if (comingList != null) {
      scheduleList = comingList
          .map((e) => LedModel.fromJson(json.decode(e)))
          .toList();
      notifyListeners();
    }
  }

  // Lưu dữ liệu vào SharedPreferences
  void saveData() {
    listOfString = scheduleList.map((e) => json.encode(e.toJson())).toList();
    preferences.setStringList("data", listOfString);
    notifyListeners();
  }

  // Khởi tạo thông báo
  Future<void> initializeNotifications(BuildContext con) async {
    context = con;
    var androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitSettings = DarwinInitializationSettings();
    var initSettings = InitializationSettings(
        android: androidInitSettings, iOS: iOSInitSettings);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin!.initialize(initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  // Xử lý khi nhận thông báo
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
    }
    await Navigator.push(
        context, MaterialPageRoute<void>(builder: (context) => MyApp()));
  }

  // Hiển thị thông báo ngay lập tức
  Future<void> showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin!.show(
        0, 'plain title', 'plain body', notificationDetails,
        payload: 'item x');
  }

  // Đặt lịch thông báo
  Future<void> scheduleNotification(DateTime dateTime, int id) async {
    int newTime =
        dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;

    if (newTime > 0) {
      await flutterLocalNotificationsPlugin!.zonedSchedule(
        id,
        'Control Led',
        "Your alarm is set for ${DateFormat().format(dateTime)}",
        tz.TZDateTime.now(tz.local).add(Duration(milliseconds: newTime)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            importance: Importance.max,
            priority: Priority.high,
            autoCancel: false,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Hủy thông báo dựa trên ID
  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin!.cancel(notificationId);
  }

  void checkTimers(
      List<LedModel> timerSchedules, Function updateLedStatus) {
    final now = DateTime.now();
    String currentDay = DateFormat('EEE').format(now);
    String currentTime = timeFormat.format(now);

    for (var schedule in timerSchedules) {
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
