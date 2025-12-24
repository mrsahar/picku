import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/services/share_pref.dart';
import 'package:pick_u/services/global_variables.dart';

import '../utils/theme/mcolors.dart';
import 'home/home_screen.dart';

class MainMap extends StatefulWidget {
  const MainMap({super.key});

  @override
  State<MainMap> createState() => _MainMapState();
}

class _MainMapState extends State<MainMap> {
  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      drawer: buildModernDrawer(context, isDark),
      body: Stack(
        children: [
          const HomeScreen(),
          Positioned(
            top: 45, // space from top
            left: 20,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Builder(
                    builder: (context) => IconButton(
                        icon: const Icon(LineAwesomeIcons.bars_solid),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildModernDrawer(BuildContext context, bool isDark) {
    return Drawer(
      width: context.width * 0.75,
      child: Container(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Custom Header
            _buildDrawerHeader(context, isDark),

            // Main Menu Section
            _buildMenuSection(
              title: 'MENU',
              isDark: isDark,
              children: [
                _ModernMenuTile(
                  icon: LineAwesomeIcons.user_solid,
                  title: 'Profile',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.profileScreen),
                ),
                _ModernMenuTile(
                  icon: LineAwesomeIcons.history_solid,
                  title: 'History',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.rideHistory),
                ),
                _ModernMenuTile(
                  icon: LineAwesomeIcons.comment,
                  title: 'Schedule Ride',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.scheduledRideHistory),
                ),
                _ModernMenuTile(
                  icon: LineAwesomeIcons.bell_solid,
                  title: 'Notifications',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.notificationScreen),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Financial Section
            // _buildMenuSection(
            //   title: 'FINANCIAL',
            //   isDark: isDark,
            //   children: [
            //     _ModernMenuTile(
            //       icon: LineAwesomeIcons.wallet_solid,
            //       title: 'Wallet',
            //       isDark: isDark,
            //       onTap: () {},
            //     ),
            //   ],
            // ),

            const SizedBox(height: 16),

            // Settings Section
            _buildMenuSection(
              title: 'SETTINGS',
              isDark: isDark,
              children: [
                _ModernMenuTile(
                  icon: LineAwesomeIcons.cog_solid,
                  title: 'Settings',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.settingsScreen),
                ),
                _ModernMenuTile(
                  icon: LineAwesomeIcons.broadcast_tower_solid,
                  title: 'Help Center',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.helpCenterScreen),
                ),
                _ModernMenuTile(
                  icon: LineAwesomeIcons.question_circle_solid,
                  title: 'Privacy Policy',
                  isDark: isDark,
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Logout Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _ModernMenuTile(
                icon: LineAwesomeIcons.sign_out_alt_solid,
                title: 'Logout',
                isDark: isDark,
                isLogout: true,
                onTap: () => logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer Header Widget
  Widget _buildDrawerHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Logo ---
          Image.asset(
            isDark ? "assets/img/only_logo.png" : "assets/img/logo.png",
            height: 70,
          ),

          const SizedBox(height: 28),

          // --- Avatar + User Info ---
          FutureBuilder<String?>(
            future: SharedPrefsService.getUserFullName(),
            builder: (context, snapshot) {
              final userName = snapshot.data?.toUpperCase() ?? 'Guest User';
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Avatar with Badge ---
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              MColor.trackingOrange,
                              MColor.trackingOrange.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MColor.trackingOrange.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LineAwesomeIcons.user_solid,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // --- Name and Role ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- User Name or Loading Skeleton ---
                      isLoading
                          ? Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                          : Text(
                        userName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // --- Role Tag ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: MColor.trackingOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 12,
                              color: MColor.trackingOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Passenger',
                              style: TextStyle(
                                color: MColor.trackingOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Menu Section Widget
  Widget _buildMenuSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> logout() async {
    try {
      bool? confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Logout', style: TextStyle(color: MColor.danger)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Clear user data from SharedPreferences
        await SharedPrefsService.clearUserData();

        // Clear GlobalVariables
        final globalVars = GlobalVariables.instance;
        globalVars.setLoginStatus(false);
        globalVars.setUserToken('');
        globalVars.setUserEmail('');

        // Navigate to login screen and remove all previous routes
        Get.offAllNamed(AppRoutes.loginScreen);

        Get.snackbar(
          'Success',
          'Logged out successfully',
          backgroundColor: MColor.primaryNavy,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        backgroundColor: MColor.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}

// Modern Menu Tile Widget
class _ModernMenuTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final String? badge;
  final Color? badgeColor;
  final bool isLogout;

  const _ModernMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.badge,
    this.badgeColor,
    this.isLogout = false,
  });

  @override
  State<_ModernMenuTile> createState() => _ModernMenuTileState();
}

class _ModernMenuTileState extends State<_ModernMenuTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.08);
    final hoverBgColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.12);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animationController.reverse(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isLogout ? Colors.red.withValues(alpha: 0.08) : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isLogout
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              hoverColor: hoverBgColor,
              splashColor: MColor.trackingOrange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isLogout
                            ? Colors.red.withValues(alpha: 0.15)
                            : MColor.trackingOrange.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.isLogout ? Colors.red : MColor.trackingOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isLogout
                              ? Colors.red
                              : widget.isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    // Badge
                    if (widget.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.badgeColor ?? MColor.trackingOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
