import 'package:app_thue_phong/controller/provider/themProvider/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeChangeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged; // Callback để thay đổi theme sáng/tối
  final Function(bool)
  onSystemThemeChanged; // Callback để thay đổi sử dụng cài đặt hệ thống

  const ThemeChangeScreen({
    super.key,
    required this.onThemeChanged,
    required this.onSystemThemeChanged,
  });

  @override
  State<ThemeChangeScreen> createState() => _ThemeChangeScreenState();
}

class _ThemeChangeScreenState extends State<ThemeChangeScreen> {
  bool _isDarkMode =
      false; // Trạng thái cục bộ của giao diện trong màn hình này
  bool _useSystemTheme =
      false; // Trạng thái cục bộ của việc sử dụng cài đặt hệ thống

  void _switchToLightMode() {
    setState(() => _isDarkMode = false);

    // Gọi provider để thay đổi theme toàn cục
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(false);
  }

  void _switchToDarkMode() {
    setState(() => _isDarkMode = true);

    // Gọi provider để thay đổi theme toàn cục
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(true);
  }

  // Hàm thay đổi sử dụng cài đặt hệ thống
  void _toggleSystemTheme(bool value) {
    setState(() {
      _useSystemTheme = value;
    });
    widget.onSystemThemeChanged(
      _useSystemTheme,
    ); // Gọi callback (nếu có xử lý riêng)
    debugPrint('System theme set to: $_useSystemTheme');
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao diện'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiển thị',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () => _switchToLightMode(),
                  child: Column(
                    children: [
                      Icon(Icons.wb_sunny, size: 50, color: Colors.orange),
                      const Text('Sáng'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _switchToDarkMode(),

                  child: Column(
                    children: [
                      Icon(Icons.nights_stay, size: 50, color: Colors.blueGrey),
                      const Text('Tối'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  'Sử dụng cài đặt của thiết bị',
                  style:
                      textColor == Colors.white
                          ? const TextStyle(color: Colors.white)
                          : const TextStyle(color: Colors.black),
                ),
                Spacer(),
                Switch(value: _useSystemTheme, onChanged: _toggleSystemTheme),
              ],
            ),
            const SizedBox(height: 30),
         
          ],
        ),
      ),
    );
  }
}
