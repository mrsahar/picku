import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/services/location_service.dart';
import 'package:pick_u/services/search_location_service.dart';
import 'package:pick_u/services/map_service.dart';
import 'package:pick_u/services/google_places_service.dart';
import 'package:pick_u/models/location_model.dart';
import 'package:pick_u/utils/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/utils/theme/mcolors.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class RideBookingPage extends StatelessWidget {
  late final RideBookingController controller;

  // Inject services directly
  final LocationService _locationService = Get.find<LocationService>();
  final SearchService _searchService = Get.find<SearchService>();
  final MapService _mapService = Get.find<MapService>();

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
      appBar: PickUAppBar(
        title: "Book a Ride",
        onBackPressed: () {
          Get.back();
        },
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
          // Schedule Toggle Section
          Obx(() => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: controller.isScheduled.value
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.isScheduled.value
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 0.8, // Adjust scale (0.8 = 80% of original size)
                  child: Switch(
                    value: controller.isScheduled.value,
                    onChanged: (value) {
                      controller.toggleScheduling();
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Ride',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: controller.isScheduled.value
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        controller.isScheduled.value
                            ? 'Book a ride for later'
                            : 'Book a ride now',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),

          // Date and Time Fields (shown only when scheduled)
          Obx(() {
            if (controller.isScheduled.value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Date Selection
                  Text(
                    'Select Date',
                    style: theme.textTheme.titleSmall?.copyWith(color:MColor.primaryNavy ,fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.scheduledDate.value != null
                                  ? DateFormat('EEEE, MMM dd, yyyy').format(controller.scheduledDate.value!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 16,
                                color: controller.scheduledDate.value != null
                                    ? theme.colorScheme.onSurface
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time Selection
                  Text(
                    'Select Time',
                    style: theme.textTheme.titleSmall?.copyWith(color:MColor.primaryNavy ,fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.scheduledTime.value != null
                                  ? controller.scheduledTime.value!.format(context)
                                  : 'Select time',
                              style: TextStyle(
                                fontSize: 16,
                                color: controller.scheduledTime.value != null
                                    ? theme.colorScheme.onSurface
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Schedule Summary
                  if (controller.scheduledDate.value != null && controller.scheduledTime.value != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ride scheduled for ${DateFormat('MMM dd, yyyy').format(controller.scheduledDate.value!)} at ${controller.scheduledTime.value!.format(context)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 16),
          // Pickup Location
          Text(
            'Pickup Location',
            style: theme.textTheme.titleSmall?.copyWith(color:MColor.primaryNavy ,fontWeight: FontWeight.bold),
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
                  onChanged: (value) => _searchService.searchLocation(value, 'pickup'),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => ElevatedButton(
                onPressed: _locationService.isLocationLoading.value ? null : () async {
                  await _setPickupToCurrentLocation();
                  _handleLocationSelectionAutoCalculate();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: _locationService.isLocationLoading.value
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
            style: theme.textTheme.titleSmall?.copyWith(color:MColor.primaryNavy ,fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLocationTextField(
            controller: controller.dropoffController,
            hintText: 'Enter dropoff location',
            icon: Icons.location_on,
            iconColor: MAppTheme.primaryNavyColor,
            onChanged: (value) => _searchService.searchLocation(value, 'dropoff'),
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
                              onChanged: (value) => _searchService.searchLocation(value, 'stop_$index'),
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.removeStop(index),
                            icon: Icon(Icons.remove_circle, color: MColor.danger),
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
          // Search Suggestions - Updated to use SearchService directly
          Obx(() {
            if (_searchService.searchSuggestions.isNotEmpty || _searchService.isSearching.value) {

              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 250),
                child: Column(
                  children: [
                    // Loading indicator
                    if (_searchService.isSearching.value)
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
                    if (_searchService.searchSuggestions.isNotEmpty && !_searchService.isSearching.value)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchService.searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final prediction = _searchService.searchSuggestions[index];
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
                              subtitle: (prediction.types.isNotEmpty &&
                                  prediction.types.first.replaceAll('_', ' ')
                                      .toUpperCase() != "GEOCODE")
                                  ? Text(
                                prediction.types.first.replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              )
                                  : null,
                              onTap: () async {
                                await _selectSuggestion(prediction);
                                await _handleLocationSelectionAutoCalculate();
                              },
                            );
                          },
                        ),
                      ),

                    // No results message
                    if (_searchService.searchSuggestions.isEmpty &&
                        !_searchService.isSearching.value &&
                        _searchService.activeSearchField.value.isNotEmpty)
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

          // Route Preview (if locations are set and ride not started)
          Obx(() {
            if (controller.pickupLocation.value != null &&
                controller.dropoffLocation.value != null &&
                controller.isRideBooked.value &&
                controller.rideStatus.value != 'driver_assigned' &&
                controller.rideStatus.value != 'driver_on_way' &&
                controller.rideStatus.value != 'trip_started' &&
                controller.rideStatus.value != 'completed') {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
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
                    const Text('✓ Pickup & Drop-off selected'),
                    if (controller.additionalStops.isNotEmpty)
                      Text('✓ ${controller.additionalStops.length} additional stop(s) added'),
                    Obx(() {
                      // Recalculate fare whenever distance changes
                      String currentDistance = _mapService.routeDistance.value;
                      if (currentDistance.isNotEmpty && _mapService.routeDuration.value.isNotEmpty) {
                        // Trigger fare calculation on distance change
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.getFareEstimate();
                        });

                        return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✓ Distance: $currentDistance'),
                                    Text('✓ Duration: ${_mapService.routeDuration.value}'),
                                    Text('✓ Estimated Fare: \$${controller.estimatedFare.value}'),
                                  ],
                                ),
                              ),
                              if (_mapService.isLoadingRoute.value)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          );
                      }
                      return const SizedBox.shrink();
                    })
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 20),
          // Passenger Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
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
                Future.delayed(const Duration(milliseconds: 300), () async {
                  try {
                    await controller.showPickupLocationWithZoom();
                  } catch (e) {
                    print(' SAHArError showing pickup location: $e');
                  }
                });
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

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.scheduledDate.value ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setScheduledDate(picked);
    }
  }

  // Time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.scheduledTime.value ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate that the selected time is not in the past
      if (controller.scheduledDate.value != null) {
        DateTime selectedDateTime = DateTime(
          controller.scheduledDate.value!.year,
          controller.scheduledDate.value!.month,
          controller.scheduledDate.value!.day,
          picked.hour,
          picked.minute,
        );

        if (selectedDateTime.isBefore(DateTime.now())) {
          Get.snackbar(
            'Invalid Time',
            'Please select a time in the future',
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }

      controller.setScheduledTime(picked);
    }
  }

  // Method to set pickup location using LocationService
  Future<void> _setPickupToCurrentLocation() async {
    try {
      await _locationService.getCurrentLocation();

      var currentLocationData = _locationService.getCurrentLocationData();
      if (currentLocationData != null) {
        controller.pickupController.text = currentLocationData.address;
        controller.pickupLocation.value = currentLocationData;
      } else {
        Get.snackbar('Error', 'Could not get current location');
      }
    } catch (e) {
      //Get.snackbar('Error', 'Failed to get current location: $e');
    }
  }

  // Method to handle search suggestion selection using SearchService
  Future<void> _selectSuggestion(AutocompletePrediction prediction) async {
    try {
      controller.isLoading.value = true;
      _searchService.searchSuggestions.clear();

      PlaceDetails? placeDetails = await _searchService.getPlaceDetails(prediction.placeId);
      if (placeDetails == null) return;

      String activeField = _searchService.activeSearchField.value;

      if (activeField == 'pickup') {
        controller.pickupController.text = placeDetails.formattedAddress;
        controller.pickupLocation.value = LocationData(
          address: placeDetails.formattedAddress,
          latitude: placeDetails.location.latitude,
          longitude: placeDetails.location.longitude,
          stopOrder: 0,
        );
      } else if (activeField == 'dropoff') {
        controller.dropoffController.text = placeDetails.formattedAddress;
        controller.dropoffLocation.value = LocationData(
          address: placeDetails.formattedAddress,
          latitude: placeDetails.location.latitude,
          longitude: placeDetails.location.longitude,
          stopOrder: 1,
        );
      }
      else if (activeField.startsWith('stop_')) {
        int stopIndex = int.parse(activeField.split('_')[1]);
        if (stopIndex < controller.stopControllers.length) {
          controller.stopControllers[stopIndex].text = placeDetails.formattedAddress;

          LocationData stopData = LocationData(
            address: placeDetails.formattedAddress,
            latitude: placeDetails.location.latitude,
            longitude: placeDetails.location.longitude,
            stopOrder: stopIndex + 2,
          );

          if (stopIndex < controller.additionalStops.length) {
            controller.additionalStops[stopIndex] = stopData;
          } else {
            controller.additionalStops.add(stopData);
          }
        }
      }

      _searchService.activeSearchField.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to select location');
    } finally {
      controller.isLoading.value = false;
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
        print(' SAHArError calculating route: $e');
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
