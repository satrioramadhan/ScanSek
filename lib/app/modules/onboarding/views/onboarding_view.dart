import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import '../../../themes/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              PageView(
                controller: controller.pageController,
                onPageChanged: (index) =>
                    controller.currentPageIndex.value = index,
                children: [
                  onboardingContent(
                    image: 'assets/images/onboarding1.png',
                    title: 'Gulanya Kebanyakan Gak Nih?',
                    subtitle:
                        'Scan aja pake ScanSek!\nLangsung tau berapa sendok teh gulanya\n& auto ke-record buat harianmu.',
                  ),
                  onboardingContent(
                    image: 'assets/images/onboarding2.png',
                    title: 'Udah Minum Belum Nih?',
                    subtitle:
                        'ScanSek bisa ngingetin kamu minum.\nBiar gak dehidrasi dan tetep fresh!',
                  ),
                  onboardingContent(
                    image: 'assets/images/onboarding3.png',
                    title: 'Hidup Sehat, Nggak Ribet~',
                    subtitle:
                        'Pake ScanSek, semuanya lebih gampang.\nGula kekontrol, badan tetep chill🍃',
                  ),
                  onboardingFinalScreen(), // Logo screen
                ],
              ),
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Obx(() => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: controller.currentPageIndex.value == index
                              ? 12
                              : 8,
                          height: controller.currentPageIndex.value == index
                              ? 12
                              : 8,
                          decoration: BoxDecoration(
                            color: controller.currentPageIndex.value == index
                                ? AppColors.primary
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        )),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  children: controller.currentPageIndex.value < 3
                      ? [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  controller.pageController.jumpToPage(3),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppColors.accent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text("Skip",
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  controller.pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text("Next",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ]
                      : [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('sudahOnboarding', true);
                                Get.offAllNamed(
                                    Routes.REGISTER); // pake Routes biar rapi
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppColors.accent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('sudahOnboarding', true);
                                Get.offAllNamed(Routes.LOGIN);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget onboardingContent({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(image, height: 400, width: 280),
            ),
          ),
          SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget onboardingFinalScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Hero(
          tag: 'logo',
          child: Image.asset('assets/images/logo.png', height: 350),
        ),
        SizedBox(height: 30),
        Text(
          "Mulai hidup kontrol gula\nbareng ScanSek!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
