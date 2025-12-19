import 'package:get/get.dart';
import 'package:pick_u/authentication/edit_profile_screen.dart';
import 'package:pick_u/authentication/forget_password_screen.dart';
import 'package:pick_u/authentication/login_screen.dart';
import 'package:pick_u/authentication/otp_screen.dart';
import 'package:pick_u/authentication/profile_screen.dart';
import 'package:pick_u/authentication/reset_password_screen.dart';
import 'package:pick_u/authentication/signup_screen.dart';
import 'package:pick_u/bindings/chat_binding.dart';
import 'package:pick_u/bindings/edit_profile_binding.dart';
import 'package:pick_u/bindings/forgot_password_binding.dart';
import 'package:pick_u/bindings/login_binding.dart';
import 'package:pick_u/bindings/main_map_binding.dart';
import 'package:pick_u/bindings/otp_binding.dart';
import 'package:pick_u/bindings/profile_binding.dart';
import 'package:pick_u/bindings/reset_password_binding.dart';
import 'package:pick_u/bindings/ride_history_binding.dart';
import 'package:pick_u/bindings/scheduled_ride_history_binding.dart';
import 'package:pick_u/bindings/signup_binding.dart';
import 'package:pick_u/routes/app_route_observer.dart';
import 'package:pick_u/taxi/chat_screen.dart';
import 'package:pick_u/taxi/history/history_screen.dart';
import 'package:pick_u/taxi/main_map.dart';
import 'package:pick_u/taxi/scheduled/scheduled_ride_history_page.dart';
import 'package:pick_u/taxi/screens/help_center_screen.dart';
import 'package:pick_u/taxi/screens/notification_screen.dart';
import 'package:pick_u/taxi/screens/privacy_policy_screen.dart';
import 'package:pick_u/taxi/screens/setting_screen.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.loginScreen;

  // Observer instance
  static final MyRouteObserver routeObserver = MyRouteObserver();

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.signupScreen,
      page: () => const SignupScreen(),
      binding: SignUpBinding(),
    ),
    GetPage(
    name: AppRoutes.profileScreen,
    page: () => const ProfileScreen(),
    binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.otpScreen,
      page: () => const OTPScreen(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.loginScreen,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.mainMap,
      page: () => const MainMap(),
      binding: MainMapBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPasswordScreen,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordScreen(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.rideHistory,
      page: () => const RideHistoryPage(),
      binding: RideHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.scheduledRideHistory,
      page: () => const ScheduledRideHistoryPage(),
      binding: ScheduledRideHistoryBinding(),
    ),

    // Extra
    GetPage(
      name: AppRoutes.notificationScreen,
      page: () => const NotificationScreen(),
    ),
    GetPage(
      name: AppRoutes.settingsScreen,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.helpCenterScreen,
      page: () => const HelpCenterScreen(),
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const PrivacyPolicyScreen(),
    ),
    GetPage(
      name: AppRoutes.chatScreen,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transitionDuration: const Duration(milliseconds: 300),
    )

  ];
}