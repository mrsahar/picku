import 'package:flutter/material.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/providers/api_provider.dart';
import 'package:pick_u/utils/theme/app_theme.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:pick_u/bindings/initial_binding.dart';
import 'package:pick_u/routes/app_pages.dart';

import 'core/global_variables.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Initialize global variables
  Get.put(GlobalVariables());
  runApp(const MyApp());
  initializeServices();
}

void initializeServices() {
  Get.put(LocationService());
  Get.put(ApiProvider());
  Get.put(RideController());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initialState();

  }

  void initialState() async{
    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PickU',
      theme: MAppTheme.lightTheme,
      darkTheme: MAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      navigatorObservers: [AppPages.routeObserver],
      initialRoute: AppPages.INITIAL, // Keep this
      getPages: AppPages.routes,      // Keep this
      // Remove the home property completely
    );
  }
}
