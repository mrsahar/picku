import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/widget/picku_appbar.dart';
import 'package:pick_u/controllers/settings_controller.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? MColor.darkBg : MColor.lightBg,
      appBar: PickUAppBar(
        title: "Settings",
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.sync_solid),
            onPressed: () => controller.refreshAll(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Location Section
          _buildSettingItem(
            icon: LineAwesomeIcons.map_marker_solid,
            title: 'Location',
            subtitle: '${controller.locationPermissionStatus.value} • ${controller.isLocationEnabled.value ? 'Active' : 'Inactive'}',
            isDark: isDark,
            onTap: controller.openLocationSettings,
          ),

          _buildDivider(isDark),


          // Notifications
          _buildSettingItem(
            icon: LineAwesomeIcons.bell_solid,
            title: 'Notifications',
            subtitle: controller.isNotificationEnabled.value ? 'Enabled' : 'Disabled',
            isDark: isDark,
            onTap: controller.openNotificationSettings,
          ),

          _buildDivider(isDark),

          // GPS Accuracy
          _buildSettingItem(
            icon: LineAwesomeIcons.crosshairs_solid,
            title: 'GPS Accuracy',
            subtitle: '${controller.gpsAccuracy.value} • ${controller.lastLocationUpdate.value}',
            isDark: isDark,
            onTap: controller.refreshLocationAccuracy,
          ),

          _buildDivider(isDark),

          // Storage
          _buildSettingItem(
            icon: LineAwesomeIcons.database_solid,
            title: 'Storage',
            subtitle: controller.isCalculatingCache.value ? 'Calculating...' : controller.cacheSize.value,
            isDark: isDark,
            onTap: controller.clearCache,
            trailing: const Icon(LineAwesomeIcons.trash_solid, size: 18),
          ),

          _buildDivider(isDark),

          // Rate App
          _buildSettingItem(
            icon: LineAwesomeIcons.star_solid,
            title: 'Rate PickU',
            subtitle: 'Help us grow by rating the app',
            isDark: isDark,
            onTap: controller.rateApp,
          ),

          _buildDivider(isDark),

          // About
          _buildSettingItem(
            icon: LineAwesomeIcons.info_circle_solid,
            title: 'About',
            subtitle: 'Version ${controller.appVersion.value} (${controller.appBuildNumber.value})',
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2025 PickU. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: MColor.mediumGrey,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      )),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MColor.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: MColor.primaryNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? MColor.white : MColor.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: MColor.mediumGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                LineAwesomeIcons.angle_right_solid,
                color: MColor.mediumGrey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? MColor.darkGrey : MColor.lightGrey,
      ),
    );
  }



}

