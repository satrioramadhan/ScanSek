import 'package:flutter/material.dart';

class CustomReminder {
  final TimeOfDay time;
  final String title;
  final String body;

  CustomReminder({
    required this.time,
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toMap() => {
        'hour': time.hour,
        'minute': time.minute,
        'title': title,
        'body': body,
      };

  factory CustomReminder.fromMap(Map<String, dynamic> map) {
    return CustomReminder(
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }

  String get timeFormatted =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
