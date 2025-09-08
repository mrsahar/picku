import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/controllers/chat_controller.dart';
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
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.3),
              blurRadius: 10.0,
              offset: const Offset(0, -4), // Shadow at the top
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: inputBorderColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title - Dynamic arrival time with SignalR integration
            Obx(() => Text(
              controller.rideStatus.value == RideStatus.tripStarted
                  ? "Trip in Progress"
                  : controller.rideStatus.value == RideStatus.driverAssigned
                  ? "Your Ride is arriving in 3 mins"
                  : controller.rideStatus.value == RideStatus.tripCompleted
                  ? "Trip Completed"
                  : "Driver Assigned",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            )),

            const SizedBox(height: 8.0),
            // Divider
            Divider(color: theme.dividerColor, thickness: 0.4),
            const SizedBox(height: 16.0),

            // Driver Info Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Message Icon - Enhanced chat functionality
                _buildCircularButton(
                  icon: Icons.message,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () => _handleChatNavigation(controller),
                ),
                // Driver Info
                Column(
                  children: [
                    // Driver Profile Picture
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Obx(() => CircleAvatar(
                          radius: 36.0,
                          backgroundColor: theme.primaryColor,
                          child: Text(
                            controller.driverName.value.isNotEmpty
                                ? controller.driverName.value[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                        Positioned(
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14.0),
                                const SizedBox(width: 2),
                                Text(
                                  "4.5",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // Driver Name - Dynamic
                    Obx(() => Text(
                      controller.driverName.value.isNotEmpty
                          ? controller.driverName.value
                          : "Driver",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    )),
                    const SizedBox(height: 4.0),

                    // Phone and Vehicle Info
                    Column(
                      children: [
                        // Driver Phone
                        Obx(() => Text(
                          controller.driverPhone.value.isNotEmpty
                              ? controller.driverPhone.value
                              : "Phone not available",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontSize: 12.0,
                          ),
                        )),
                        const SizedBox(height: 2.0),
                        // Vehicle Info
                        Obx(() => Text(
                          controller.vehicle.value.isNotEmpty
                              ? "${controller.vehicle.value} ${controller.vehicleColor.value}"
                              : "No data about the car",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontSize: 14.0,
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
                // Call Icon - Enhanced with actual calling functionality
                _buildCircularButton(
                  icon: Icons.call,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () => _makePhoneCall(controller.driverPhone.value, controller.driverName.value),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Price Information - Enhanced with real-time updates
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: MColor.primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MColor.primaryNavy.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.rideStatus.value == RideStatus.tripCompleted
                            ? 'Final Price'
                            : 'Estimated Price',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Obx(() => Text(
                        '₹${controller.estimatedPrice.value.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: controller.rideStatus.value == RideStatus.tripCompleted
                              ? Colors.green
                              : theme.primaryColor,
                        ),
                      )),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ride Type',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Obx(() => Text(
                        controller.rideType.value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),
            // Dynamic Button - Enhanced with pricing display
            Obx(() => _buildRideActionButton(controller, theme)),
          ],
        ),
      ),
    ],
  );
}

// Enhanced chat navigation with proper service integration
void _handleChatNavigation(RideBookingController controller) {
  // Check if ChatController already exists
  ChatController? existingChatController;
  try {
    existingChatController = Get.find<ChatController>();
  } catch (e) {
    existingChatController = null;
  }

  if (existingChatController != null) {
    // Update existing ChatController and navigate back to existing ChatScreen
    existingChatController.updateRideInfo(
      rideId: controller.currentRideId.value,
      driverId: controller.driverId.value,
      driverName: controller.driverName.value,
    );

    // Check if we're already on ChatScreen, if not navigate to it
    if (Get.currentRoute != AppRoutes.chatScreen) {
      Get.toNamed(AppRoutes.chatScreen);
    }
  } else {
    // First time opening chat, create new ChatScreen with arguments
    Get.toNamed(AppRoutes.chatScreen, arguments: {
      'rideId': controller.currentRideId.value,
      'driverId': controller.driverId.value,
      'driverName': controller.driverName.value,
    });
  }
}

// Enhanced phone call functionality
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

  // Clean phone number (remove spaces, dashes, etc.)
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

// Enhanced ride action button with pricing information
Widget _buildRideActionButton(RideBookingController controller, ThemeData theme) {
  print('SAHAr Current ride status: ${controller.rideStatus.value}'); // Debug log

  switch (controller.rideStatus.value) {
    case RideStatus.tripStarted:
    // Show End Trip button with estimated final price
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColor.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: controller.isLoading.value ? null : () async {
                // Show confirmation dialog with price
                bool confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('End Trip'),
                    content: Text(
                        'Are you sure you want to end this trip?\n\nEstimated final price: ₹${controller.estimatedPrice.value.toStringAsFixed(2)}'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(backgroundColor: MColor.primaryNavy),
                        child: const Text('End Trip', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ) ?? false;

                if (confirm) {
                  await controller.endTrip();
                }
              },
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("End Trip"),
            ),
          ),
        ],
      );

    case RideStatus.tripCompleted:
    // Show completion status with final price
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: MColor.primaryNavy, size: 32),
            const SizedBox(height: 8),
            Text(
              'Trip Completed!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MColor.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );

    case RideStatus.driverAssigned:
    // Show Start Trip button when driver is assigned
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MColor.primaryNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: controller.isLoading.value ? null : () async {
            await controller.startTrip();
          },
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Start Trip"),
        ),
      );

    case RideStatus.waiting:
    // Show waiting status
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Looking for drivers...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

    case RideStatus.cancelled:
    // Show cancelled status
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MColor.primaryNavy.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MColor.primaryNavy.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.cancel, color: MColor.primaryNavy, size: 32),
            const SizedBox(height: 8),
            Text(
              'Ride Cancelled',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MColor.primaryNavy,
              ),
            ),
          ],
        ),
      );

    default:
    // For debugging - show current status
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Current Status: ${controller.rideStatus.value.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
  }
}

// Helper method to build circular buttons
Widget _buildCircularButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
  required bool isDarkMode,
}) {
  // Adjust background color for better contrast in dark mode
  final backgroundColor = isDarkMode
      ? const Color(0xFFFFC900) // Slightly higher opacity for dark mode
      : color.withOpacity(0.2); // Lighter opacity for light mode

  return GestureDetector(
    onTap: onPressed,
    child: CircleAvatar(
      radius: 24.0,
      backgroundColor: backgroundColor,
      child: Icon(icon, color: color, size: 28.0),
    ),
  );
}
