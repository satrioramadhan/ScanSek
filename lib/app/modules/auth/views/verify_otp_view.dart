import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scan_sek/app/modules/auth/controllers/auth_controller.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart';
import 'dart:async';

class VerifyOtpView extends StatefulWidget {
  final String email;

  VerifyOtpView({required this.email});

  @override
  _VerifyOtpViewState createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  List<TextEditingController> textControllers =
      List.generate(6, (_) => TextEditingController());

  bool isButtonEnabled = true;
  int countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
  }

  void _initializeCountdown() async {
    final authController = Get.find<AuthController>();
    int remaining =
        await authController.getRemainingOtpCountdown('otp_countdown_end');
    if (remaining > 0) {
      setState(() {
        countdown = remaining;
        isButtonEnabled = false;
      });
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          isButtonEnabled = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    final authController = Get.find<AuthController>();
    await authController.resendOtp(widget.email);
    int remaining =
        await authController.getRemainingOtpCountdown('otp_countdown_end');
    if (remaining > 0) {
      setState(() {
        countdown = remaining;
        isButtonEnabled = false;
      });
      _startCountdownTimer();
    } else {
      SnackbarHelper.show('Gagal', 'Tidak bisa mendapatkan waktu hitung mundur',
          type: 'error');
    }
  }

  String formatCountdown() {
    int minutes = countdown ~/ 60;
    int seconds = countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    focusNodes.forEach((f) => f.dispose());
    textControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Email'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.offAllNamed(Routes.LOGIN);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Verifikasi OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Masukkan kode OTP yang dikirim ke ${widget.email}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => _otpTextField(index)),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final otp = textControllers.map((c) => c.text).join();
                if (otp.length < 6) {
                  SnackbarHelper.show('Error', 'Masukkan OTP lengkap',
                      type: 'error');
                  return;
                }
                authController.verifikasiOtp(widget.email, otp);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Verifikasi', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: isButtonEnabled ? _resendOtp : null,
              child: Text(
                isButtonEnabled
                    ? "Belum menerima kode? Kirim ulang"
                    : "Kirim ulang dalam ${formatCountdown()}",
                style: TextStyle(
                  color: isButtonEnabled ? Colors.redAccent : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpTextField(int index) {
    return Container(
      width: 40,
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: textControllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
