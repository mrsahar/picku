import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/chat_controller.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/core/signalr_service.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:url_launcher/url_launcher.dart';

Widget driverInfoWidget(BuildContext context) {
  final theme = Theme.of(context);
  var brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
  final controller = Get.find<RideBookingController>();
  final signalRService = Get.find<SignalRService>();

  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Obx(() {
        // Only show when driver is assigned and location is active
        if (controller.rideStatus.value != RideStatus.driverAssigned &&
            controller.rideStatus.value != RideStatus.tripStarted) {
          return const SizedBox.shrink();
        }

        if (!controller.isDriverLocationActive.value) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
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
                child: IconButton(
                  icon: Icon(
                    Icons.my_location,
                    color: MColor.primaryNavy,
                    size: 20,
                  ),
                  onPressed: () => controller.centerOnDriverLocation(),
                  tooltip: 'Center on Driver',
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        );
      }),

      // Main Driver Info Container - Compact Design
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: theme.cardColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            const SizedBox(height: 16),

            // Compact Header with Status
            Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      controller.rideStatus.value,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(controller.rideStatus.value),
                    size: 16,
                    color: _getStatusColor(controller.rideStatus.value),
                  ),
                ),
                const SizedBox(width: 12),
                // Status Text
                Expanded(
                  child: Obx(
                    () => Text(
                      _getStatusText(controller.rideStatus.value),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.navigation, size: 14, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  controller.getFormattedDistanceToDriver(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Compact Driver Info Row
            Row(
              children: [
                // Driver Avatar with Rating
                Stack(
                  children: [
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.cardColor,
                          child: Text(
                            controller.driverName.value.isNotEmpty
                                ? controller.driverName.value[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.cardColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "4.5",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Driver Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          controller.driverName.value.isNotEmpty
                              ? controller.driverName.value
                              : "Driver",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          controller.vehicle.value.isNotEmpty
                              ? "${controller.vehicle.value} ${controller.vehicleColor.value}"
                              : "Vehicle info",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons - Compact
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactButton(
                      icon: Icons.message_outlined,
                      color: theme.primaryColor,
                      onPressed: () => _handleChatNavigation(controller),
                    ),
                    const SizedBox(width: 8),
                    _buildCompactButton(
                      icon: Icons.call_outlined,
                      color: Colors.green,
                      onPressed: () => _makePhoneCall(
                        controller.driverPhone.value,
                        controller.driverName.value,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Compact Price & Ride Info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: MColor.primaryNavy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MColor.primaryNavy.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => Text(
                                '₹${controller.estimatedPrice.value.toStringAsFixed(0)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      controller.rideStatus.value ==
                                          RideStatus.tripCompleted
                                      ? Colors.green
                                      : theme.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              controller.rideStatus.value ==
                                      RideStatus.tripCompleted
                                  ? 'Final'
                                  : 'Estimated',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(
                    () => Text(
                  controller.rideType.value,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Button - Compact
            Obx(() => _buildCompactRideActionButton(controller, theme)),
          ],
        ),
      ),
    ],
  );
}

// Helper method to build compact buttons
Widget _buildCompactButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

// Helper method to get status colors
Color _getStatusColor(RideStatus status) {
  switch (status) {
    case RideStatus.tripStarted:
      return Colors.blue;
    case RideStatus.driverAssigned:
      return Colors.orange;
    case RideStatus.tripCompleted:
      return Colors.green;
    case RideStatus.cancelled:
      return Colors.red;
    case RideStatus.waiting:
      return Colors.amber;
    default:
      return Colors.grey;
  }
}

// Helper method to get status icons
IconData _getStatusIcon(RideStatus status) {
  switch (status) {
    case RideStatus.tripStarted:
      return Icons.drive_eta;
    case RideStatus.driverAssigned:
      return Icons.person_pin_circle;
    case RideStatus.tripCompleted:
      return Icons.check_circle;
    case RideStatus.cancelled:
      return Icons.cancel;
    case RideStatus.waiting:
      return Icons.hourglass_empty;
    default:
      return Icons.info;
  }
}

// Helper method to get status text
String _getStatusText(RideStatus status) {
  switch (status) {
    case RideStatus.tripStarted:
      return "Trip in Progress";
    case RideStatus.driverAssigned:
      return "Driver is coming";
    case RideStatus.tripCompleted:
      return "Trip Completed";
    case RideStatus.cancelled:
      return "Ride Cancelled";
    case RideStatus.waiting:
      return "Finding driver...";
    default:
      return "Processing...";
  }
}

// Compact ride action button
Widget _buildCompactRideActionButton(
  RideBookingController controller,
  ThemeData theme,
) {
  switch (controller.rideStatus.value) {
    case RideStatus.tripStarted:
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  bool confirm =
                      await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('End Trip'),
                          content: Text(
                            'End this trip?\n\nEstimated: ₹${controller.estimatedPrice.value.toStringAsFixed(2)}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MColor.primaryNavy,
                              ),
                              child: const Text(
                                'End Trip',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (confirm) {
                    await controller.endTrip();
                  }
                },
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("End Trip"),
        ),
      );

    case RideStatus.tripCompleted:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Trip Completed Successfully',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );

    case RideStatus.driverAssigned:
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MColor.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  await controller.startTrip();
                },
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Start Trip"),
        ),
      );

    case RideStatus.waiting:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Looking for drivers...',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

    case RideStatus.cancelled:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ride Cancelled',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );

    default:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Status: ${controller.rideStatus.value.name}',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
  }
}

// Keep your existing helper functions unchanged
void _handleChatNavigation(RideBookingController controller) {
  ChatController? existingChatController;
  try {
    existingChatController = Get.find<ChatController>();
  } catch (e) {
    existingChatController = null;
  }

  if (existingChatController != null) {
    existingChatController.updateRideInfo(
      rideId: controller.currentRideId.value,
      driverId: controller.driverId.value,
      driverName: controller.driverName.value,
    );

    if (Get.currentRoute != AppRoutes.chatScreen) {
      Get.toNamed(AppRoutes.chatScreen);
    }
  } else {
    Get.toNamed(
      AppRoutes.chatScreen,
      arguments: {
        'rideId': controller.currentRideId.value,
        'driverId': controller.driverId.value,
        'driverName': controller.driverName.value,
      },
    );
  }
}

Future<void> _makePhoneCall(String phoneNumber, String driverName) async {
  if (phoneNumber.isEmpty) {
    Get.snackbar(
      'Error',
      'Driver phone number not available',
      snackPosition: SnackPosition.TOP,
      backgroundColor: MColor.primaryNavy.withOpacity(0.8),
      colorText: Colors.white,
    );
    return;
  }

  String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  final Uri phoneUri = Uri.parse('tel:$cleanedNumber');

  try {
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);

      Get.snackbar(
        'Calling',
        'Calling $driverName...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      throw 'Could not launch phone dialer';
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Unable to make call. Please try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: MColor.primaryNavy.withOpacity(0.8),
      colorText: Colors.white,
    );
  }
}
