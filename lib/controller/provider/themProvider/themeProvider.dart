import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false; // Trạng thái manual (dark nếu true)
  bool _useSystemTheme = false; // Nếu true, sử dụng cài đặt của thiết bị

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;

  // Thay đổi manual theme
  void toggleTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }

  // Thay đổi trạng thái sử dụng hệ thống
  void toggleSystemTheme(bool useSystemTheme) {
    _useSystemTheme = useSystemTheme;
    notifyListeners();
  }
}
