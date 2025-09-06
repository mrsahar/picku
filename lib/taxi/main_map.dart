import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/authentication/profile_screen.dart';
import 'package:pick_u/core/sharePref.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/taxi/car/select_car_screen.dart';
import 'package:pick_u/taxi/home/driver_screen.dart';
import 'package:pick_u/taxi/home/home_screen.dart';
import 'package:pick_u/taxi/payment/select_payment_page.dart';
import 'package:pick_u/taxi/wallet/wallet_screen.dart';
import 'package:pick_u/utils/profile_widget_menu.dart';

import '../utils/theme/mcolors.dart';

class MainMap extends StatefulWidget {
  const MainMap({super.key});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  final _currentIndex = 0;

  List<Widget> pageList = [
    const HomeScreen(),
    const DriverScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    //final textColor = isDark ? Colors.white : Colors.black;
   // final iconColor = isDark ? Colors.orange : Colors.black;

    return Scaffold(
      drawer: Drawer(
        width: context.width * .7,
        child: Container(
          color: bgColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: (isDark)
                          ? Image.asset("assets/img/only_logo.png")
                          : Image.asset("assets/img/logo.png"),
                    ),
                    const SizedBox(height: 20,),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(1.0),
                      child: Row(
                        children: [
                          Icon(LineAwesomeIcons.at_solid, size: 18.0,color: MColor.trackingOrange,),
                          SizedBox(width: 2.0),
                          FutureBuilder<String?>(
                            future: SharedPrefsService.getUserFullName(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 14.0,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                );
                              }

                              return Text(
                                snapshot.data ?? 'Guest',
                                style: const TextStyle(fontSize: 14.0),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),

              ),
              ProfileMenuWidget(
                  title: "Home",
                  icon: LineAwesomeIcons.home_solid,
                  onPress: () {}),
              ProfileMenuWidget(
                  title: "Profile",
                  icon: LineAwesomeIcons.user_solid,
                  onPress: () {
                    Get.toNamed(AppRoutes.profileScreen);
                  }),
              ProfileMenuWidget(
                  title: "History",
                  icon: LineAwesomeIcons.history_solid,
                  onPress: () {
                    Get.toNamed(AppRoutes.rideHistory);
                  }),
              Container(height: 8),ProfileMenuWidget(
                  title: "Scheduled Ride",
                  icon: LineAwesomeIcons.comment,
                  onPress: () {
                    Get.toNamed(AppRoutes.scheduledRideHistory);
                  }),
              ProfileMenuWidget(
                  title: "Wallet",
                  icon: LineAwesomeIcons.wallet_solid,
                  onPress: () {}),
              ProfileMenuWidget(
                  title: "Settings",
                  icon: LineAwesomeIcons.tools_solid,
                  onPress: () {
                    Get.to(() => const SelectCarPage());
                  }),
              ProfileMenuWidget(
                  title: "Feedback",
                  icon: LineAwesomeIcons.comment,
                  onPress: () {
                    Get.to(() => const PaymentMethodsPage());
                  }),

              Container(height: 8),
              const Divider(
                height: 1,
              ),
              ProfileMenuWidget(
                  title: "Logout",
                  textColor: Colors.red,
                  icon: LineAwesomeIcons.sign_out_alt_solid,
                  onPress: () {
                    Get.to(() => const DriverScreen());
                  }),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          pageList.elementAt(_currentIndex),
          Builder(
            builder: (context) => Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(LineAwesomeIcons.bars_solid),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
