import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  var currentPageIndex = 0.obs;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
