import 'package:app_thue_phong/controller/provider/authProvider/mobileAuthProvider.dart';
import 'package:app_thue_phong/controller/provider/themProvider/themeProvider.dart';
import 'package:app_thue_phong/view/authScreen/mobileLoginScreen.dart';
import 'package:app_thue_phong/view/homeScreen/homeScreen.dart';
import 'package:app_thue_phong/view/ruleScreen/ruleScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Xử lý thông báo nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Xử lý thông báo nền: ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Xin quyền nhận thông báo trên iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('🔔 Đã được cấp quyền nhận thông báo!');
  } else {
    debugPrint('❌ Không được cấp quyền nhận thông báo!');
  }

  // Lấy FCM Token để sử dụng cho thông báo
  String? token = await messaging.getToken();
  debugPrint('🔥 FCM Token: $token');

  // Xử lý thông báo khi ứng dụng đang mở (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
      '🔔 Nhận thông báo khi đang mở ứng dụng: ${message.notification?.title}',
    );
    if (message.notification != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder:
            (context) => AlertDialog(
              title: Text(message.notification!.title ?? 'Thông báo'),
              content: Text(
                message.notification!.body ?? 'Nội dung không xác định',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    }
  });

  // Xử lý khi người dùng nhấn vào thông báo từ trạng thái nền hoặc đã bị đóng
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
      '🔔 Người dùng nhấn vào thông báo: ${message.notification?.title}',
    );
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  });
}

// GlobalKey để xử lý navigation từ bất kỳ nơi nào trong app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Lấy cờ isFirstRun, nếu chưa có thì mặc định là true
  final isFirstRun = prefs.getBool('isFirstRun') ?? true;

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFirebaseMessaging();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/lang',
      fallbackLocale: const Locale('vi', 'VN'),
      startLocale: const Locale('vi', 'VN'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => MobileAuthProvider()),
        ],
        child: MyApp(isFirstRun: isFirstRun),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({Key? key, required this.isFirstRun}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              themeMode:
                  themeProvider.useSystemTheme
                      ? ThemeMode.system
                      : (themeProvider.isDarkMode
                          ? ThemeMode.dark
                          : ThemeMode.light),
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: SplashScreen(isFirstRun: isFirstRun),
            );
          },
        );
      },
    );
  }
}

// Widget SplashScreen hiển thị hình splash trước khi chuyển hướng
class SplashScreen extends StatefulWidget {
  final bool isFirstRun;
  const SplashScreen({Key? key, required this.isFirstRun}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Hiển thị splash screen trong 3 giây trước khi chuyển màn hình
    Future.delayed(const Duration(seconds: 3), () async {
      // Kiểm tra trạng thái đăng nhập
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Nếu là lần đầu mở app thì hiển thị RulesScreen (onboarding)
        if (widget.isFirstRun) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RulesScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MobileLoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
