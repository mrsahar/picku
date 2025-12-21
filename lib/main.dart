import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pick_u/utils/theme/app_theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:pick_u/bindings/initial_binding.dart';
import 'package:pick_u/routes/app_pages.dart';
import 'package:pick_u/services/notification_service.dart';
import 'package:pick_u/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/global_variables.dart';

 void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: "assets/.env");

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  await Stripe.instance.applySettings();

  // Initialize services early
  Get.put(NotificationService(), permanent: true);
  Get.put(AuthController(), permanent: true);

  FlutterNativeSplash.remove();
  Get.lazyPut(() =>GlobalVariables());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    initialState();
    _loadThemeMode();
  }

  void initialState() async{
    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_mode') ?? 'system';

      setState(() {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      });
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PickU',
      theme: MAppTheme.lightTheme,
      darkTheme: MAppTheme.darkTheme,
      themeMode: _themeMode,
      initialBinding: InitialBinding(),
      navigatorObservers: [AppPages.routeObserver],
      initialRoute: AppPages.INITIAL, // Keep this
      getPages: AppPages.routes,      // Keep this
      // Remove the home property completely
    );
  }
}
