import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'Chào mừng bạn đến với ứng dụng thuê phòng!\n\n'
              'Hướng dẫn sử dụng:\n'
              '1. Hồ sơ: Quản lý thông tin cá nhân của bạn.\n'
              '2. Hóa đơn: Xem và thanh toán hóa đơn thuê phòng.\n'
              '3. Thông báo: Nhận thông báo quan trọng từ hệ thống.\n'
              '4. Trò chuyện: Liên hệ với chủ nhà hoặc bộ phận hỗ trợ.\n'
              '5. Hướng dẫn sử dụng: Xem hướng dẫn và thông tin trợ giúp về ứng dụng.\n'
              '6. Đăng xuất: Thoát khỏi tài khoản của bạn.\n\n'
              'Nếu cần trợ giúp thêm, vui lòng liên hệ với chúng tôi qua mục Hỗ trợ.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
