// ignore_for_file: use_build_context_synchronously
import 'dart:developer';
import 'package:app_thue_phong/view/homeScreen/homeScreen.dart';
import 'package:app_thue_phong/view/ruleScreen/ruleScreen.dart';
 
import 'package:app_thue_phong/view/userRegister/userRegistraionScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constants.dart';
import '../../../view/authScreen/mobileLoginScreen.dart';
import '../../../view/authScreen/otpScreen.dart';
import '../../../view/signinLogicScreen/signLogicScreen.dart';
import '../../provider/authProvider/mobileAuthProvider.dart';

class MobileAuthServices {
  static Future<String?> getFCMToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        log('FCM Token: $fcmToken');
        return fcmToken;
      }
    } catch (e) {
      log('Lỗi lấy FCM Token: $e');
    }
    return null;
  }

  static receiveOTP({
    required BuildContext context,
    required String mobileNo,
  }) async {
    try {
      log("Bắt đầu gửi OTP cho số: $mobileNo");
      await auth.verifyPhoneNumber(
        phoneNumber: mobileNo,
        verificationCompleted: (PhoneAuthCredential credentials) {
          log("Xác thực tự động thành công với credentials: $credentials");
        },
        verificationFailed: (FirebaseAuthException exception) {
          log("Xác thực OTP thất bại: ${exception.toString()}");
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 16,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        "Bạn nhập sai số điện thoại",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MobileLoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        codeSent: (String verificationID, int? resendToken) {
          log("OTP đã được gửi, verificationID: $verificationID");
          context.read<MobileAuthProvider>().updateVerificationID(
            verificationID,
          );
          Navigator.push(
            context,
            PageTransition(
              child: const OTPScreen(),
              type: PageTransitionType.rightToLeft,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationID) {
          log("Mã OTP hết hạn, verificationID: $verificationID");
        },
      );
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException trong receiveOTP: ${e.toString()}");
      throw Exception(e);
    }
  }

  static Future<void> verifyOTP({
    required BuildContext context,
    required String otp,
  }) async {
    try {
      log("Bắt đầu xác thực OTP: $otp");
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: context.read<MobileAuthProvider>().verificationID!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      log("Xác thực OTP thành công, chuyển sang kiểm tra đăng ký người dùng");
      await checkUserRegistration(context: context);
    } catch (e) {
      log('Lỗi xác thực OTP: ${e.toString()}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapOTPError(e))));
    }
  }

  static String _mapOTPError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-verification-code':
          return 'Mã OTP không hợp lệ';
        case 'session-expired':
          return 'Phiên đăng nhập hết hạn';
        default:
          return 'Lỗi xác thực: ${error.code}';
      }
    }
    return 'Lỗi không xác định';
  }

  static Future<void> checkUserRegistration({
    required BuildContext context,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("Không tìm thấy user, chuyển về MobileLoginScreen");
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
          (route) => false,
        );
        return;
      }

      final String? phoneNumber = user.phoneNumber;
      if (phoneNumber == null) {
        log("User không có số điện thoại, chuyển về MobileLoginScreen");
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
          (route) => false,
        );
        return;
      }

      log("User tồn tại với số điện thoại: $phoneNumber");

      String? fcmToken = await getFCMToken();
      final DocumentReference userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber);
      final DocumentSnapshot doc = await userDoc.get();

      if (doc.exists) {
        log("User đã đăng ký trong Firestore, cập nhật FCM Token");
        await userDoc.update({'fcmToken': fcmToken});

        // Kiểm tra SharedPreferences để xác định đã hoàn tất Onboarding chưa
        final prefs = await SharedPreferences.getInstance();
        final bool isFirstRun = prefs.getBool("isFirstRun") ?? true;
        log("Giá trị isFirstRun: $isFirstRun");

        if (isFirstRun) {
          log("Chưa hoàn tất Onboarding, chuyển hướng sang RulesScreen");
          Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
              child: RulesScreen(),
              type: PageTransitionType.rightToLeft,
            ),
            (route) => false,
          );
        } else {
          log("Đã hoàn tất Onboarding, chuyển hướng sang HomeScreen");
          Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
              child: const HomeScreen(),
              type: PageTransitionType.rightToLeft,
            ),
            (route) => false,
          );
        }
      } else {
        log("User chưa đăng ký, chuyển sang UserRegistrationScreen");
        Navigator.pushAndRemoveUntil(
          context,
          PageTransition(
            child: const UserRegistrationScreen(),
            type: PageTransitionType.rightToLeft,
          ),
          (route) => false,
        );
      }
    } catch (e) {
      log('Lỗi checkUserRegistration: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi hệ thống, vui lòng thử lại')),
        );
      }
    }
  }

  static signOut(BuildContext context) {
    log("Đăng xuất user");
    auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const SignInLogicScreen();
        },
      ),
      (route) => false,
    );
  }
}
