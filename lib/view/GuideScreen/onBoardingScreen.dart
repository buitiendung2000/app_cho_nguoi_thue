import 'package:app_thue_phong/view/homeScreen/homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingData {
  final String title;
  final String description;
  final String imageAssetPath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imageAssetPath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      title: 'Chào Mừng Bạn',
      description: 'Hãy làm theo các bước để bắt đầu hành trình của bạn',
      imageAssetPath: 'assets/images/onboarding1.png',
    ),
    OnboardingData(
      title: 'Quản lý hồ sơ cá nhân',
      description:
          'Hãy cập nhật thông tin cá nhân của bạn chính xác để chúng tôi dễ dàng quản lý',
      imageAssetPath: 'assets/images/onboarding2.png',
    ),
    OnboardingData(
      title: 'Hóa Đơn',
      description: 'Dễ dàng thanh toán và quản lý hóa đơn của bạn',
      imageAssetPath: 'assets/images/onboarding3.png',
    ),
    OnboardingData(
      title: 'Thông báo',
      description: 'Nhận thông báo mới nhất từ Chủ trọ',
      imageAssetPath: 'assets/images/onboarding3.png',
    ),
    OnboardingData(
      title: 'Trò chuyện',
      description: 'Dễ dàng bước vào những cuộc tán gẫu vui vẻ cùng mọi người',
      imageAssetPath: 'assets/images/onboarding3.png',
    ),
    OnboardingData(
      title: 'Hướng dẫn sử dụng',
      description: 'Khi bạn gặp khó khăn gì hãy xem hướng dẫn sử dụng',
      imageAssetPath: 'assets/images/onboarding3.png',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isFirstRun", false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child:
                  _currentPage < onboardingPages.length - 1
                      ? TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: const Text(
                          "Bỏ qua",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : const SizedBox(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) {
                  final page = onboardingPages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(page.imageAssetPath, height: 250),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(onboardingPages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 30 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        _currentPage == index ? Colors.deepPurple : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == onboardingPages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == onboardingPages.length - 1
                        ? "Bắt đầu ngay"
                        : "Tiếp tục",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
