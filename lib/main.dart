import 'package:flutter/material.dart';
import 'package:pick_u/screens/splash_screen.dart';
import 'package:pick_u/utils/theme/app_theme.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
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
    //await Future.delayed(const Duration(seconds: 3));
    //FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'picku',
        theme: MAppTheme.lightTheme,
        darkTheme:MAppTheme.darkTheme,
        themeMode: ThemeMode.system,

        home: const SplashScreen(),
      );
  }
}
