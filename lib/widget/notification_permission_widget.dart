import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/services/notification_service.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class NotificationPermissionWidget extends StatelessWidget {
  final Widget child;
  final bool showPermissionDialog;

  const NotificationPermissionWidget({
    Key? key,
    required this.child,
    this.showPermissionDialog = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notificationService = NotificationService.to;

      // Auto-check permissions when widget builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (showPermissionDialog &&
            notificationService.isInitialized &&
            !notificationService.notificationsEnabled) {
          _showPermissionRequest(context);
        }
      });

      return child;
    });
  }

  void _showPermissionRequest(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Get.theme.primaryColor,
            ),
            const SizedBox(width: 12),
            const Text('Enable Notifications'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stay connected with your driver!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable notifications to receive:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('💬 Chat messages from your driver'),
            _buildFeatureItem('📍 Trip status updates'),
            _buildFeatureItem('🚗 Driver arrival notifications'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Required for Android 12+ devices',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await NotificationService.to.checkAndRequestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              color: Get.theme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsButton extends StatelessWidget {
  const NotificationSettingsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final notificationService = NotificationService.to;

      return ListTile(
        leading: Icon(
          notificationService.notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: notificationService.notificationsEnabled
              ? MColor.primaryNavy
              : Colors.grey,
        ),
        title: const Text('Chat Notifications'),
        subtitle: Text(
          notificationService.notificationsEnabled
              ? 'Enabled - You\'ll receive message notifications'
              : 'Disabled - Tap to enable notifications',
        ),
        trailing: notificationService.notificationsEnabled
            ? Icon(Icons.check_circle, color: MColor.primaryNavy)
            : const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          if (!notificationService.notificationsEnabled) {
            final granted = await notificationService.checkAndRequestPermissions();
            if (!granted) {
              Get.snackbar(
                'Permission Required',
                'Please enable notifications in device settings to receive chat messages.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: MColor.warning,
                colorText: MColor.warning,
                duration: const Duration(seconds: 5),
                mainButton: TextButton(
                  onPressed: () => notificationService.checkAndRequestPermissions(),
                  child: const Text('Try Again'),
                ),
              );
            }
          } else {
            // Show info about current notification status
            Get.snackbar(
              'Notifications Enabled',
              'You\'re all set to receive chat notifications!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: MColor.primaryNavy,
              colorText: MColor.primaryNavy,
              icon: Icon(Icons.check_circle, color: MColor.primaryNavy),
            );
          }
        },
      );
    });
  }
}

// Usage example for your chat screen
class ChatScreenWithNotifications extends StatelessWidget {
  const ChatScreenWithNotifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationPermissionWidget(
      showPermissionDialog: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          actions: [
            Obx(() {
              final notificationService = NotificationService.to;
              return IconButton(
                icon: Icon(
                  notificationService.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: notificationService.notificationsEnabled
                      ? Colors.white
                      : Colors.grey,
                ),
                onPressed: () {
                  notificationService.checkAndRequestPermissions();
                },
                tooltip: 'Notification Settings',
              );
            }),
          ],
        ),
        body: const Center(
          child: Text('Your chat content here'),
        ),
      ),
    );
  }
}
