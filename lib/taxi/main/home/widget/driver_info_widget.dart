import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';

Widget driverInfoWidget(BuildContext context) {
  final theme = Theme.of(context);
  var brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
  final controller = Get.find<RideBookingController>();

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
            // Title - Dynamic arrival time
            Obx(() => Text(
              controller.rideStatus.value == 'trip_started'
                  ? "Trip in Progress"
                  : controller.rideStatus.value == 'driver_on_way'
                  ? "Your Ride is arriving in 3 mins"
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
                // Message Icon
                _buildCircularButton(
                  icon: Icons.message,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    Get.snackbar('Message', 'Messaging feature coming soon!');
                  },
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
                        // Vehicle Info (placeholder since not in API response)
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
                // Call Icon
                _buildCircularButton(
                  icon: Icons.call,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    if (controller.driverPhone.value.isNotEmpty) {
                      Get.snackbar(
                        'Calling',
                        'Calling ${controller.driverName.value}...',
                        duration: const Duration(seconds: 2),
                      );
                      // Here you can add actual calling functionality
                    } else {
                      Get.snackbar('Error', 'Driver phone not available');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Price Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Price',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      Obx(() => Text(
                        '₹${controller.estimatedPrice.value.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
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
            // Dynamic Button - Only Start Trip or End Trip
            Obx(() {
              if (controller.rideStatus.value == 'trip_started') {
                // Show End Trip button when trip is started
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: controller.isLoading.value ? null : () async {
                      await controller.endTrip();
                    },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("End Trip"),
                  ),
                );
              } else {
                // Show Start Trip button
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
              }
            }),
          ],
        ),
      ),
    ],
  );
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
