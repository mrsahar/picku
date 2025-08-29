import 'package:get/get.dart';
import 'package:pick_u/routes/app_route_observer.dart';
import 'package:pick_u/authentication/forget_password_screen.dart';
import 'package:pick_u/authentication/login_screen.dart';
import 'package:pick_u/authentication/otp_screen.dart';
import 'package:pick_u/authentication/reset_password_screen.dart';
import 'package:pick_u/authentication/signup_screen.dart';
import 'package:pick_u/bindings/forgot_password_binding.dart';
import 'package:pick_u/bindings/login_binding.dart';
import 'package:pick_u/bindings/otp_binding.dart';
import 'package:pick_u/bindings/reset_password_binding.dart';
import 'package:pick_u/bindings/signup_binding.dart';
import 'package:pick_u/taxi/main/main_map.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.MainMap;

  // Observer instance
  static final MyRouteObserver routeObserver = MyRouteObserver();

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.SIGNUP_SCREEN,
      page: () => const SignupScreen(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: AppRoutes.OTP_SCREEN,
      page: () => const OTPScreen(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN_SCREEN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.MainMap,
      page: () => const MainMap(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD_SCREEN,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.Reset_Password,
      page: () => const ResetPasswordScreen(),
      binding: ResetPasswordBinding(),
    ),

  ];
}