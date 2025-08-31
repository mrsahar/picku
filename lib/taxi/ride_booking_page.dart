import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/utils/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class RideBookingPage extends StatelessWidget {
  late final RideBookingController controller;

  RideBookingPage({super.key}) {
    try {
      controller = Get.find<RideBookingController>();
    } catch (e) {
      controller = Get.put(RideBookingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        elevation: 0,
        actions: [
          // Clear all button
          TextButton(
            onPressed: () {
              controller.clearBooking();
              Get.snackbar('Cleared', 'All locations cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
      body: _buildLocationInputView(context),
    );
  }

  Widget _buildLocationInputView(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup Location
          Text(
            'Pickup Location',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildLocationTextField(
                  controller: controller.pickupController,
                  hintText: 'Enter pickup location',
                  icon: Icons.my_location,
                  iconColor: MAppTheme.primaryNavyColor,
                  onChanged: (value) => controller.searchLocation(value, 'pickup'),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () async {
                  await _getCurrentLocationWithGPSCheck();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.gps_fixed, color: Colors.white),
              )),
            ],
          ),

          const SizedBox(height: 16),

          // Dropoff Location
          Text(
            'Dropoff Location',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLocationTextField(
            controller: controller.dropoffController,
            hintText: 'Enter dropoff location',
            icon: Icons.location_on,
            iconColor: MAppTheme.primaryNavyColor,
            onChanged: (value) => controller.searchLocation(value, 'dropoff'),
          ),

          // Additional Stops
          Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.stopControllers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Additional Stops',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...controller.stopControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stopController = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildLocationTextField(
                              controller: stopController,
                              hintText: 'Stop ${index + 1}',
                              icon: Icons.add_location,
                              iconColor: MAppTheme.primaryNavyColor,
                              onChanged: (value) => controller.searchLocation(value, 'stop_$index'),
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.removeStop(index),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            );
          }),

          // Add Stop Button
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.addStop,
            icon: const Icon(Icons.add),
            label: const Text('Add Stop'),
          ),

          // Search Suggestions
          Obx(() {
            if (controller.searchSuggestions.isNotEmpty || controller.isSearching.value) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 250),
                child: Column(
                  children: [
                    // Loading indicator
                    if (controller.isSearching.value)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Searching locations...'),
                          ],
                        ),
                      ),

                    // Search results
                    if (controller.searchSuggestions.isNotEmpty && !controller.isSearching.value)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final prediction = controller.searchSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                _getIconForPlaceType(prediction.types),
                                size: 20,
                                color: Colors.blue,
                              ),
                              title: Text(
                                prediction.description,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              subtitle: prediction.types.isNotEmpty
                                  ? Text(
                                prediction.types.first.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              )
                                  : null,
                              onTap: () async {
                                await controller.selectSuggestion(prediction);
                                // Auto-calculate when dropoff or stop is selected
                                await _handleLocationSelectionAutoCalculate();
                              },
                            );
                          },
                        ),
                      ),

                    // No results message
                    if (controller.searchSuggestions.isEmpty &&
                        !controller.isSearching.value &&
                        controller.activeSearchField.value.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.search_off, color: Colors.grey),
                            SizedBox(width: 12),
                            Text('No locations found. Try a different search term.'),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 24),

          // Route Preview (if locations are set)
          Obx(() {
            if (controller.pickupLocation.value != null &&
                controller.dropoffLocation.value != null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Route Preview',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('✓ Pickup and dropoff locations set'),
                    if (controller.additionalStops.isNotEmpty)
                      Text('✓ ${controller.additionalStops.length} additional stop(s) added'),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 16),
          Obx(() {
            if (controller.routeDistance.value.isNotEmpty && controller.routeDuration.value.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route Information',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Distance: ${controller.routeDistance.value}'),
                          Text('Duration: ${controller.routeDuration.value}'),
                        ],
                      ),
                    ),
                    if (controller.isLoadingRoute.value)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 16),

          // Passenger Count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Passengers:', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (controller.passengerCount.value > 1) {
                          controller.passengerCount.value--;
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${controller.passengerCount.value}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        if (controller.passengerCount.value < 8) {
                          controller.passengerCount.value++;
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            )),
          ),

          const SizedBox(height: 24),

          // Book Ride Button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: (controller.isLoading.value ||
                  controller.pickupLocation.value == null ||
                  controller.dropoffLocation.value == null)
                  ? () => Get.back()
                  : () async {
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.dropoffLocation.value == null
                  ? const Text(
                'Go Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              )
                  : const Text(
                'Show Map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // Method to check GPS and enable it automatically
  Future<void> _getCurrentLocationWithGPSCheck() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog asking user to enable GPS
        Get.dialog(
          AlertDialog(
            title: const Text('GPS Required'),
            content: const Text('GPS is required for this feature. Would you like to enable it?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  // Try to open location settings
                  bool opened = await Geolocator.openLocationSettings();
                  if (opened) {
                    // Wait a bit and check again
                    await Future.delayed(const Duration(seconds: 2));
                    bool isEnabled = await Geolocator.isLocationServiceEnabled();
                    if (isEnabled) {
                      await controller.getCurrentLocation();
                    } else {
                      Get.snackbar('Error', 'GPS is still disabled. Please enable it manually.');
                    }
                  } else {
                    Get.snackbar('Error', 'Unable to open GPS settings. Please enable GPS manually.');
                  }
                },
                child: const Text('Enable GPS'),
              ),
            ],
          ),
        );
        return;
      }

      // Check for permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Error', 'Location permissions are permanently denied');
        return;
      }

      // Get current location
      await controller.getCurrentLocation();
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: ${e.toString()}');
    }
  }

  // Method to handle auto-calculation when location is selected
  Future<void> _handleLocationSelectionAutoCalculate() async {
    // Small delay to ensure the location is properly set in the controller
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if both pickup and dropoff are set, then calculate
    if (controller.pickupLocation.value != null &&
        controller.dropoffLocation.value != null) {
      try {
        await controller.bookRide();
      } catch (e) {
        print('Error calculating route: $e');
        // You might want to show a snackbar here if needed
      }
    }
  }

  Widget _buildLocationTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    Color? iconColor,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  IconData _getIconForPlaceType(List<String> types) {
    if (types.contains('establishment') || types.contains('point_of_interest')) {
      return Icons.place;
    } else if (types.contains('route')) {
      return Icons.add_road;
    } else if (types.contains('locality') || types.contains('administrative_area_level_1')) {
      return Icons.location_city;
    } else if (types.contains('airport')) {
      return Icons.flight;
    } else if (types.contains('hospital')) {
      return Icons.local_hospital;
    } else if (types.contains('school') || types.contains('university')) {
      return Icons.school;
    } else if (types.contains('shopping_mall')) {
      return Icons.shopping_cart;
    } else if (types.contains('restaurant') || types.contains('food')) {
      return Icons.restaurant;
    } else {
      return Icons.location_on;
    }
  }
}