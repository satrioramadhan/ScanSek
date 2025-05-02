import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TargetController extends GetxController {
  RxInt targetGula = 50.obs;
  RxInt targetAir = 8.obs;

  RxBool notifGula = false.obs;
  RxBool notifAir = false.obs;

  RxList<TimeOfDay> reminderList = <TimeOfDay>[].obs;

  void setTargetGula(int value) => targetGula.value = value;
  void setTargetAir(int value) => targetAir.value = value;

  void toggleNotifGula(bool value) => notifGula.value = value;
  void toggleNotifAir(bool value) => notifAir.value = value;

  void pickReminderTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      reminderList.add(picked);
      reminderList.sort((a, b) => a.hour.compareTo(b.hour) != 0
          ? a.hour.compareTo(b.hour)
          : a.minute.compareTo(b.minute));
    }
  }

  void removeReminder(TimeOfDay time) {
    reminderList.remove(time);
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
    return DateFormat.Hm().format(dt);
  }
}
