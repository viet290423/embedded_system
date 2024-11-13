// fan_provider.dart

import 'dart:convert';
import 'dart:async';
import 'package:embedded_system/page/fan_page.dart';
import 'package:embedded_system/page/main_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:embedded_system/model/fan_model.dart'; // Model dành riêng cho quạt
import 'package:embedded_system/main.dart';

class FanProvider extends ChangeNotifier {
  late SharedPreferences preferences;

  List<FanSchedule> fanSchedules = []; // Danh sách các lịch hẹn giờ cho quạt
  List<String> listOfString = []; // Danh sách lưu dưới dạng String
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  late BuildContext context;

  final DateFormat timeFormat = DateFormat("HH:mm");
  final DatabaseReference dbR = FirebaseDatabase.instance.ref();

  FanProvider() {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    preferences = await SharedPreferences.getInstance();
    notifyListeners();
  }

  // Thêm mới lịch trình cho quạt
  void addFanSchedule(
      DateTime time, List<String> repeatDays, bool isOnSetting) {
    fanSchedules.add(FanSchedule(
      time,
      repeatDays,
      isOnSetting,
    ));
    notifyListeners();
  }

  // Thay đổi trạng thái của lịch trình
  void editFanScheduleStatus(int index, bool isActive) {
    fanSchedules[index].isActive = isActive;
    notifyListeners();
  }

  // Lấy dữ liệu từ SharedPreferences
  Future<void> getFanData() async {
    preferences = await SharedPreferences.getInstance();
    List<String>? comingList = preferences.getStringList("fanData");

    if (comingList != null) {
      fanSchedules =
          comingList.map((e) => FanSchedule.fromJson(json.decode(e))).toList();
      notifyListeners();
    }
  }

  // Lưu dữ liệu vào SharedPreferences
  void saveFanData() {
    listOfString = fanSchedules.map((e) => json.encode(e.toJson())).toList();
    preferences.setStringList("fanData", listOfString);
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
  Future<void> showFanNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'fan_channel_id',
      'Fan Control Notifications',
      channelDescription: 'Notification for fan control schedule',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin!.show(
        0, 'Fan Control', 'Fan schedule notification', notificationDetails,
        payload: 'fan_control');
  }

  // Đặt lịch thông báo
  Future<void> scheduleFanNotification(
      DateTime dateTime, int id, String title, String body) async {
    int newTime =
        dateTime.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;

    if (newTime > 0) {
      await flutterLocalNotificationsPlugin!.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(Duration(milliseconds: newTime)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fan_channel_id',
            'Fan Control Notifications',
            channelDescription: 'Notification for fan control schedule',
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
  Future<void> cancelFanNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin!.cancel(notificationId);
  }

  // Kiểm tra và cập nhật trạng thái quạt dựa trên lịch trình
  void checkFanTimers(Function updateFanStatus) {
    final now = DateTime.now();
    String currentDay = DateFormat('EEE').format(now);
    String currentTime = timeFormat.format(now);

    for (var schedule in fanSchedules) {
      if (!schedule.isActive) continue;

      String scheduleTime = timeFormat.format(schedule.time);
      bool isToday = schedule.repeatDays.isEmpty;

      if (isToday || schedule.repeatDays.contains(currentDay)) {
        if (scheduleTime == currentTime) {
          if (schedule.isOnSetting) {
            dbR.child("Fan").update({"fan": true});
            updateFanStatus(true);
          } else {
            dbR.child("Fan").update({"fan": false});
            updateFanStatus(false);
          }
          if (isToday) {
            schedule.isActive = false;
          }
        }
      }
    }
  }
}
