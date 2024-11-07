class LedModel {
  final DateTime time;
  final List<String> repeatDays;
  final List<bool> selectedLEDs;
  bool isActive;
  final bool isOnSetting;

  LedModel(this.time, this.repeatDays, this.selectedLEDs, this.isOnSetting,
      {this.isActive = true});

  // Chuyển đổi đối tượng thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'repeatDays': repeatDays,
      'selectedLEDs': selectedLEDs,
      'isActive': isActive,
      'isOnSetting': isOnSetting,
    };
  }

  // Tạo đối tượng từ Map (JSON)
  factory LedModel.fromJson(Map<String, dynamic> json) {
    return LedModel(
      DateTime.parse(json['time']),
      List<String>.from(json['repeatDays']),
      List<bool>.from(json['selectedLEDs']),
      json['isOnSetting'],
      isActive: json['isActive'],
    );
  }
}
