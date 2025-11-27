import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/chat_controller.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/routes/app_routes.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:url_launcher/url_launcher.dart';

Widget driverInfoWidget(BuildContext context) {
  final theme = Theme.of(context);
  final controller = Get.find<RideBookingController>();

  return Obx(() {
    if (controller.rideStatus.value == RideStatus.waiting) {
      return _buildSearchingDriverCard(theme);
    }

    if (controller.rideStatus.value == RideStatus.cancelled) {
      return _buildCancelledCard(theme);
    }

    // Show driver info widget for all driver-related statuses
    if (controller.rideStatus.value != RideStatus.driverAssigned &&
        controller.rideStatus.value != RideStatus.driverNear &&
        controller.rideStatus.value != RideStatus.driverArrived &&
        controller.rideStatus.value != RideStatus.tripStarted &&
        controller.rideStatus.value != RideStatus.tripCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 12),
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),

          // Status row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                _getStatusColor(controller.rideStatus.value).withValues(alpha:0.15),
                child: Icon(
                  _getStatusIcon(controller.rideStatus.value),
                  size: 14,
                  color: _getStatusColor(controller.rideStatus.value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getStatusText(controller.rideStatus.value),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w300,fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.navigation, size: 14, color: MColor.primaryNavy),
              const SizedBox(width: 4),
              Text(
                controller.getFormattedDistanceToDriver(),
                style: TextStyle(fontSize: 12, color: MColor.primaryNavy),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Driver Info
          Row(
            children: [
              _buildDriverAvatar(theme, controller),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.driverName.value.isNotEmpty
                          ? controller.driverName.value
                          : "Driver",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (controller.rating.value > 0) ...[
                          const Text("⭐", style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            controller.rating.value.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.hintColor.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            controller.vehicle.value.isNotEmpty
                                ? "${controller.vehicle.value} ${controller.vehicleColor.value}"
                                : controller.rating.value > 0
                                ? "Vehicle info"
                                : "No ratings • Vehicle info",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompactButton(
                    icon: Icons.message_outlined,
                    color: theme.primaryColor,
                    onPressed: () => _handleChatNavigation(controller),
                  ),
                  const SizedBox(width: 10),
                  _buildCompactButton(
                    icon: Icons.call_outlined,
                    color: MColor.primaryNavy,
                    onPressed: () => _makePhoneCall(
                      controller.driverPhone.value,
                      controller.vehicleColor.value,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fare + Ride Type
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '\$${controller.estimatedPrice.value.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: controller.rideStatus.value == RideStatus.tripCompleted
                      ? MColor.primaryNavy
                      : theme.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                controller.rideStatus.value == RideStatus.tripCompleted
                    ? 'Final'
                    : 'Estimated',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.rideType.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Button
          _buildCompactRideActionButton(controller, theme),
        ],
      ),
    );
  });
}

Widget _buildDriverAvatar(ThemeData theme, RideBookingController controller) {
  return Stack(
    children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: theme.primaryColor.withValues(alpha:0.1),
        child: Text(
          controller.driverName.value.isNotEmpty
              ? controller.driverName.value[0].toUpperCase()
              : 'D',
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2), width: 1),
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
    case RideStatus.driverNear:
      return MColor.warning;
    case RideStatus.tripCompleted:
    case RideStatus.driverArrived:
      return MColor.primaryNavy;
    case RideStatus.cancelled:
      return MColor.danger;
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
    case RideStatus.driverNear:
    case RideStatus.driverArrived:
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
      return "Driver Assigned";
    case RideStatus.driverNear:
      return "Driver is Near";
    case RideStatus.driverArrived:
      return "Driver has Arrived";
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
                  bool confirm =
                      await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('End Ride'),
                          content: const Text(
                            'Are you sure you want to end this ride?',
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
                                'End Ride',
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
              : const Text("End Ride"),
        ),
      );

    case RideStatus.tripCompleted:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MColor.primaryNavy.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColor.primaryNavy.withValues(alpha:0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: MColor.primaryNavy, size: 20),
            const SizedBox(width: 8),
            Text(
              'Trip Completed Successfully',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MColor.primaryNavy,
              ),
            ),
          ],
        ),
      );

    case RideStatus.driverAssigned:
    case RideStatus.driverNear:
    case RideStatus.driverArrived:
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
              : const Text("Start Ride"),
        ),
      );

    case RideStatus.waiting:
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
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
          color: MColor.danger.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColor.danger.withValues(alpha:0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: MColor.danger, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ride Cancelled',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MColor.danger,
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
          color: theme.colorScheme.primary.withValues(alpha:0.1),
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
      driverName: controller.driverName.value, status: RideStatus.driverArrived,
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
      backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
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
        backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } else {
      throw 'Could not launch phone dialer';
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Unable to make call. Please try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: MColor.primaryNavy.withValues(alpha:0.8),
      colorText: Colors.white,
    );
  }
}
Widget _buildSearchingDriverCard(ThemeData theme) {
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Looking for drivers...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
Widget _buildCancelledCard(ThemeData theme) {
  return Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: MColor.danger.withValues(alpha:0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MColor.danger.withValues(alpha:0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cancel, color: MColor.danger, size: 20),
        SizedBox(width: 8),
        Text(
          'Ride Cancelled',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MColor.danger,
          ),
        ),
      ],
    ),
  );
}
