import 'dart:async';

import 'package:app_thue_phong/controller/provider/themProvider/themeProvider.dart';
import 'package:app_thue_phong/view/chatPageScreen/chatPage.dart';
import 'package:app_thue_phong/view/homeScreen/checkOutRoomScreen.dart';
import 'package:app_thue_phong/view/homeScreen/notificationScreen.dart';
import 'package:app_thue_phong/view/homeScreen/guideScreen.dart'; // Import màn hình Hướng dẫn sử dụng
import 'package:app_thue_phong/view/homeScreen/generalRulesScreen.dart'; // Import màn hình Quy định chung
import 'package:app_thue_phong/view/homeScreen/reportProblemScreen.dart';
import 'package:app_thue_phong/view/settingsScreen/languageChangeScreen.dart';
import 'package:app_thue_phong/view/settingsScreen/themeChangeScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_thue_phong/view/signinLogicScreen/signLogicScreen.dart';
import 'package:app_thue_phong/view/homeScreen/myBillScreen.dart';
import 'package:app_thue_phong/view/homeScreen/profileScreen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? phoneNumber;
  String? fullName;
  String? avatarUrl;
  bool hasUnreadNoti = false;
  bool hasUnreadMessages = false; // Biến kiểm tra tin nhắn chưa đọc
  bool hasUnreadBills = false; // Biến kiểm tra hóa đơn chưa thanh toán
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  bool _isDarkMode = false;
  bool _useSystemTheme = false;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      phoneNumber = currentUser.phoneNumber;
      updateFCMTokenToFirestore();
      fetchUserProfile();
      checkUnreadNotifications();
      _checkUnreadMessages();
      _checkUnpaidBills();
      _startListeningToMessages(); // Lắng nghe tin nhắn realtime
    }
  }

  //────────────────────────────────────────────────────────────────────────────
  // Lắng nghe tin nhắn realtime
  //────────────────────────────────────────────────────────────────────────────
  void _startListeningToMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.phoneNumber;
    if (phone == null) return;

    _messagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .snapshots()
        .listen(
          (snapshot) {
            bool unreadFound = false;
            int unreadCount = 0;
            for (var doc in snapshot.docs) {
              final data = doc.data();
              // Bỏ qua tin nhắn do chính người dùng gửi
              if (data['senderId'] == user.uid) continue;

              // Kiểm tra trường seenBy
              final seenBy = List<String>.from(data['seenBy'] ?? []);
              if (!seenBy.contains(phone)) {
                unreadFound = true;
                unreadCount++;
                debugPrint('Tin nhắn chưa đọc: ${doc.id}');
              }
            }
            debugPrint('Tổng số tin nhắn chưa đọc: $unreadCount');
            if (mounted) {
              setState(() {
                hasUnreadMessages = unreadFound;
              });
            }
          },
          onError: (error) {
            debugPrint('❌ Lỗi khi lắng nghe tin nhắn: $error');
          },
        );
  }

  //────────────────────────────────────────────────────────────────────────────
  // Kiểm tra hóa đơn chưa thanh toán
  //────────────────────────────────────────────────────────────────────────────
  Future<void> _checkUnpaidBills() async {
    if (phoneNumber == null) return;

    try {
      final billsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(phoneNumber)
              .collection('bills')
              .get();

      bool hasUnpaid = billsSnapshot.docs.any((doc) {
        final data = doc.data();
        return !(data['isPaid'] as bool? ?? false);
      });

      setState(() {
        hasUnreadBills = hasUnpaid;
        debugPrint('💰 hasUnreadBills: $hasUnreadBills');
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi kiểm tra hóa đơn chưa thanh toán: $e');
    }
  }

  // Cập nhật trạng thái hóa đơn chưa thanh toán
  void _updateBillStatus(bool hasUnpaidBill) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        hasUnreadBills = hasUnpaidBill;
      });
    });
  }

  // Cập nhật FCM Token vào Firestore
  Future<void> updateFCMTokenToFirestore() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    if (phoneNumber != null && fcmToken != null) {
      final firestore = FirebaseFirestore.instance;

      final oldTokenQuery =
          await firestore
              .collection('users')
              .where('fcmToken', isEqualTo: fcmToken)
              .get();

      for (var doc in oldTokenQuery.docs) {
        if (doc.id != phoneNumber) {
          await firestore.collection('users').doc(doc.id).update({
            'fcmToken': null,
          });
        }
      }

      await firestore.collection('users').doc(phoneNumber).update({
        'fcmToken': fcmToken,
      });

      debugPrint('✅ Đã cập nhật FCM Token: $fcmToken cho $phoneNumber');
    }
  }

  //────────────────────────────────────────────────────────────────────────────
  // Lấy hồ sơ (cập nhật avatarUrl)
  //────────────────────────────────────────────────────────────────────────────
  Future<void> fetchUserProfile() async {
    if (phoneNumber == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .get();
    if (!doc.exists) return;
    setState(() {
      fullName = doc['fullName'] ?? 'Người thuê';
      avatarUrl = doc['avatarUrl'] as String?;
    });
  }

  //────────────────────────────────────────────────────────────────────────────
  // Kiểm tra thông báo chưa đọc
  //────────────────────────────────────────────────────────────────────────────
  Future<void> checkUnreadNotifications() async {
    if (phoneNumber == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(phoneNumber)
              .get();

      final lastRead =
          userDoc.data()?['lastReadNotification'] is Timestamp
              ? userDoc['lastReadNotification'] as Timestamp
              : null;

      final latestNoti =
          await FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (latestNoti.docs.isNotEmpty) {
        final latestCreated = latestNoti.docs.first['createdAt'] as Timestamp;
        setState(() {
          hasUnreadNoti =
              lastRead == null ||
              latestCreated.toDate().isAfter(lastRead.toDate());
          debugPrint('🔔 hasUnreadNoti: $hasUnreadNoti');
        });
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi checkUnreadNotifications: $e');
    }
  }

  //────────────────────────────────────────────────────────────────────────────
  // Kiểm tra tin nhắn chưa đọc
  //────────────────────────────────────────────────────────────────────────────
  Future<void> _checkUnreadMessages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.phoneNumber;
    if (phone == null) return;

    final querySnapshot =
        await FirebaseFirestore.instance.collection('messages').get();
    int unreadCount = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['senderId'] == user.uid) continue;
      final seenBy = List<String>.from(data['seenBy'] ?? []);
      if (!seenBy.contains(phone)) {
        unreadCount++;
      }
    }
    debugPrint(
      '[_checkUnreadMessages] Tổng số tin nhắn chưa đọc: $unreadCount',
    );
    setState(() {
      hasUnreadMessages = unreadCount > 0;
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  // Hàm thay đổi giao diện sáng/tối
  void _toggleTheme(bool isDarkMode) {
    // Kiểm tra xem widget có còn tồn tại không trước khi gọi setState
    if (mounted) {
      setState(() {
        _isDarkMode = isDarkMode;
        debugPrint("Theme changed to: ${_isDarkMode ? "Dark" : "Light"}");
      });
    }
  }

  // Hàm thay đổi sử dụng cài đặt hệ thống
  void _toggleSystemTheme(bool value) {
    // Kiểm tra xem widget có còn tồn tại không trước khi gọi setState
    if (mounted) {
      setState(() {
        _useSystemTheme = value;
        debugPrint("System theme set to: $_useSystemTheme");
      });
    }
  }

  // Hàm hiển thị menu cài đặt
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text("change_theme".tr()),
              onTap: () {
                _showThemeDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text("change_language".tr()),
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('select_theme'.tr(), textAlign: TextAlign.center),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Lựa chọn giao diện Sáng
              GestureDetector(
                onTap: () {
                  // Cập nhật theme sang Light qua Provider
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme(false);
                  Navigator.pop(context); // Đóng dialog
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny, size: 60, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text('light_mode'.tr()),
                  ],
                ),
              ),
              // Lựa chọn giao diện Tối
              GestureDetector(
                onTap: () {
                  // Cập nhật theme sang Dark qua Provider
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme(true);
                  Navigator.pop(context); // Đóng dialog
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.nights_stay, size: 60, color: Colors.blueGrey),
                    const SizedBox(height: 8),
                    Text('dark_mode'.tr()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('change_language'.tr(), textAlign: TextAlign.center),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Lá cờ Tiếng Việt
              GestureDetector(
                onTap: () {
                  debugPrint('Ngôn ngữ Tiếng Việt được chọn');
                  // TODO: Gọi hàm/thư viện thay đổi ngôn ngữ
                  context.setLocale(const Locale('vi', 'VN'));
                  Navigator.pop(context); // Đóng dialog
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/vietnam.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    Text('vietnam_language'.tr()),
                  ],
                ),
              ),
              // Lá cờ Tiếng Anh
              GestureDetector(
                onTap: () {
                  debugPrint('Ngôn ngữ Tiếng Anh được chọn');
                  // TODO: Gọi hàm/thư viện thay đổi ngôn ngữ
                  context.setLocale(const Locale('en', 'US'));
                  Navigator.pop(context); // Đóng dialog
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/us.png', width: 60, height: 60),
                    const SizedBox(height: 8),
                    Text('english_language'.tr()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //────────────────────────────────────────────────────────────────────────────
  // Đăng xuất
  //────────────────────────────────────────────────────────────────────────────
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInLogicScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')));
    }
  }

  //────────────────────────────────────────────────────────────────────────────
  // Xây dựng menu card
  //────────────────────────────────────────────────────────────────────────────
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // Sử dụng cardColor theo Theme
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // Chỉ hiển thị bóng nếu ở Light Mode, Dark Mode thì có thể không cần bóng
            if (!isDark)
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showDot)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng theme để xác định màu nền
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserProfile();
          await checkUnreadNotifications();
          await _checkUnreadMessages();
          await _checkUnpaidBills();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Giả lập AppBar nằm trong body
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 16),
                color: Colors.blueGrey,
                child: Center(
                  child: Text(
                    "hello".tr(), // Hoặc thay bằng "Xin chào, bạn thuê trọ!"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueGrey.shade200,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child:
                    avatarUrl == null
                        ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        )
                        : null,
              ),
              const SizedBox(height: 10),
              Text(
                fullName ?? phoneNumber ?? 'user'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      icon: Icons.account_circle,
                      title: 'profile'.tr(),
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.receipt_long,
                      title: 'bill'.tr(),
                      color: Colors.green,
                      showDot: hasUnreadBills,
                      onTap: () {
                        if (phoneNumber != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MyBillScreen(
                                    phoneNumber: phoneNumber!,
                                    onBillStatusChanged: _updateBillStatus,
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không tìm thấy số điện thoại'),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.notifications,
                      title: 'notification'.tr(),
                      color: Colors.deepPurple,
                      showDot: hasUnreadNoti,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        ).then((_) => checkUnreadNotifications());
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.chat,
                      title: 'chat'.tr(),
                      color: Colors.blue,
                      showDot: hasUnreadMessages,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.help_outline,
                      title: 'guide'.tr(),
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GuideScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.assignment,
                      title: 'rules'.tr(),
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GeneralRulesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.report_rounded,
                      title: 'report'.tr(),
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.meeting_room,
                      title: 'check_out'.tr(),
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckOutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.settings,
                      title: 'settings'.tr(),
                      color: Colors.blueGrey,
                      onTap: () {
                        _showSettingsMenu(context);
                      },
                    ),
                    _buildMenuCard(
                      icon: Icons.logout,
                      title: 'logout'.tr(),
                      color: Colors.redAccent,
                      onTap: () => signOut(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

  }
}
