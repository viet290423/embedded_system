// fan_model.dart

class FanSchedule {
  final DateTime time;           
  final List<String> repeatDays; 
  final bool isOnSetting;
  bool isActive;                 

  FanSchedule(
    this.time,
    this.repeatDays,
    this.isOnSetting, {
    this.isActive = true,
  });

   // Chuyển đổi đối tượng thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'repeatDays': repeatDays,
      'isActive': isActive,
      'isOnSetting': isOnSetting,
    };
  }

  // Phương thức để tạo FanSchedule từ Map, dùng để tải từ Firebase
  factory FanSchedule.fromJson(Map<String, dynamic> map) {
    return FanSchedule(
      DateTime.parse(map['time']),
      List<String>.from(map['repeatDays']),
      map['isOnSetting'] as bool,
      isActive: map['isActive'] as bool,
    );
  }
}
