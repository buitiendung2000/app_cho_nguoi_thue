import 'package:flutter/material.dart';

class LanguageChangeScreen extends StatefulWidget {
  const LanguageChangeScreen({super.key});

  @override
  State<LanguageChangeScreen> createState() => _LanguageChangeScreenState();
}

class _LanguageChangeScreenState extends State<LanguageChangeScreen> {
  // Hàm dựng item cho từng lựa chọn ngôn ngữ
  Widget _buildLanguageItem(String assetPath, String label) {
    return Card(
      elevation: 4, // Đổ bóng nhẹ
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 120, // Chiều rộng cho mỗi thẻ
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetPath, width: 64, height: 64),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thay đổi ngôn ngữ'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        // Dùng Center để căn giữa hai lựa chọn
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLanguageItem(
              'assets/images/vietnam.png',
              'Ngôn ngữ Tiếng Việt',
            ),
            const SizedBox(width: 32),
            _buildLanguageItem('assets/images/us.png', 'Ngôn ngữ Tiếng Anh'),
          ],
        ),
      ),
    );
  }
}
