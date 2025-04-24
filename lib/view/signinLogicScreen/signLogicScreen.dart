import 'package:app_thue_phong/view/homeScreen/homeScreen.dart';
import 'package:app_thue_phong/view/userRegister/userRegistraionScreen.dart' show UserRegistrationScreen;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../authScreen/mobileLoginScreen.dart';
// import 'package:tinh_tien_dien_nuoc_phong_tro/view/authScreen/mobileLoginScreen.dart';
// import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';

// import 'package:tinh_tien_dien_nuoc_phong_tro/view/userRegister/userRegistraionScreen.dart';


class SignInLogicScreen extends StatelessWidget {
  const SignInLogicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ✅ Hiển thị màn hình chờ khi đang xử lý trạng thái đăng nhập
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ✅ Người dùng đã đăng nhập → Kiểm tra trạng thái đăng ký từ Firestore
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot
                    .data!.phoneNumber) // 🔥 Dùng số điện thoại làm documentId
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // ✅ Đã đăng ký → Chuyển đến HomeScreen
                return const HomeScreen();
              } else {
                // ❌ Chưa đăng ký → Chuyển đến màn hình đăng ký
                return const UserRegistrationScreen();
              }
            },
          );
        } else {
          // ❌ Người dùng chưa đăng nhập → Chuyển đến màn hình đăng nhập
          return const MobileLoginScreen();
        }
      },
    );
  }
}
