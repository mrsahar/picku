import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/services/signalr_service.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class SignalRStatusWidget extends StatelessWidget {
  const SignalRStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final signalRService = Get.find<SignalRService>();

    return Obx(() {
      final status = signalRService.connectionStatus.value;

      // Don't show widget when connected (to keep UI clean)
      if (status == SignalRConnectionStatus.connected) {
        return const SizedBox.shrink();
      }

      return Container(
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
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _handleStatusTap(status, signalRService),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildStatusIcon(status),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatusIcon(SignalRConnectionStatus status) {
    switch (status) {
      case SignalRConnectionStatus.disconnected:
        return Icon(
          Icons.wifi_off,
          color: MColor.danger,
          size: 22,
        );
      case SignalRConnectionStatus.connecting:
      case SignalRConnectionStatus.reconnecting:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.wifi,
              color: MColor.warning,
              size: 22,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: MColor.warning,
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        );
      case SignalRConnectionStatus.connected:
        return Icon(
          Icons.wifi,
          color: MColor.primaryNavy,
          size: 22,
        );
      case SignalRConnectionStatus.error:
        return Stack(
          alignment: Alignment.center,
          children: [
             Icon(
              Icons.wifi_off,
              color: MColor.danger,
              size: 22,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: MColor.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 4,
                ),
              ),
            ),
          ],
        );
    }
  }

  void _handleStatusTap(SignalRConnectionStatus status, SignalRService service) {
    switch (status) {
      case SignalRConnectionStatus.disconnected:
      case SignalRConnectionStatus.error:
        _showRetryDialog(service);
        break;
      case SignalRConnectionStatus.connecting:
      case SignalRConnectionStatus.reconnecting:
        Get.snackbar(
          'Connecting',
          'Attempting to establish connection...',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          backgroundColor: MColor.warning.withValues(alpha:0.8),
          colorText: Colors.white,
        );
        break;
      case SignalRConnectionStatus.connected:
        Get.snackbar(
          'Connected',
          'Real-time connection is active',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
          colorText: Colors.white,
        );
        break;
    }
  }

  void _showRetryDialog(SignalRService service) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: MColor.danger, size: 24),
            const SizedBox(width: 8),
            const Text('Connection Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time connection is not available. This may affect ride tracking and updates.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Troubleshooting:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('• Check your internet connection', style: TextStyle(fontSize: 12)),
                  const Text('• Try switching between WiFi/Mobile data', style: TextStyle(fontSize: 12)),
                  const Text('• Connection will retry automatically', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              service.retryConnection();
              Get.snackbar(
                'Retrying',
                'Attempting to reconnect...',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.blue.withValues(alpha:0.8),
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
