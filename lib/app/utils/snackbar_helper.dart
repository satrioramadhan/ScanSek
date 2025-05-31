import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static void show(
    String title,
    String message, {
    String type = 'info',
    Duration? duration,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;

    switch (type) {
      case 'success':
        backgroundColor = Color(0xFF95D27E); // Hijau solid
        textColor = const Color.fromARGB(255, 255, 255, 255);
        iconData = Icons.check_circle_outline;
        break;
      case 'error':
        backgroundColor = Color(0xFFFF816E); // Merah solid
        textColor = const Color.fromARGB(255, 255, 255, 255);
        iconData = Icons.error_outline;
        break;
      case 'warning':
        backgroundColor = Color(0xFFFFED91); // Orange solid
        textColor = const Color.fromARGB(221, 76, 76, 76);
        iconData = Icons.warning_amber_outlined;
        break;
      case 'info':
        backgroundColor = Color.fromARGB(255, 148, 248, 255); // Biru muda solid
        textColor = const Color.fromARGB(
            221, 47, 47, 47); // Karena biru muda, biar kontras
        iconData = Icons.info_outline;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        iconData = Icons.notifications_none;
        break;
    }

    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(iconData, color: textColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: backgroundColor,
      barBlur: 0,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: duration ?? Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      padding: EdgeInsets.all(14),
      boxShadows: [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}
