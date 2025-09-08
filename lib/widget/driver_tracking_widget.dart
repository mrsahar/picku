// Add this widget to show driver tracking status
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/core/map_service.dart';

class DriverTrackingWidget extends StatelessWidget {
  final RideBookingController controller;

  const DriverTrackingWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isDriverLocationActive.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 100,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Driver Tracking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Last update: ${_formatTime(controller.signalRService.driverLastUpdate.value)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time).inSeconds;

    if (difference < 60) {
      return 'Just now';
    } else if (difference < 3600) {
      return '${(difference / 60).round()}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// Updated to use MapService
class FitMapButton extends StatelessWidget {
  final RideBookingController controller;
  final MapService mapService;

  const FitMapButton({
    Key? key,
    required this.controller,
    required this.mapService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isDriverLocationActive.value ||
          controller.pickupLocation.value == null) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 150,
        right: 16,
        child: FloatingActionButton.small(
          onPressed: () {
            // Use MapService to fit map to show both pickup and driver
            List<LatLng> locations = [
              LatLng(
                controller.pickupLocation.value!.latitude,
                controller.pickupLocation.value!.longitude,
              ),
              LatLng(
                controller.driverLatitude.value,
                controller.driverLongitude.value,
              ),
            ];

            mapService.fitMapToLocations(locations);

            Get.snackbar(
              'Map View',
              'Showing pickup and driver locations',
              duration: const Duration(seconds: 2),
              snackPosition: SnackPosition.TOP,
            );
          },
          backgroundColor: Colors.blue,
          child: const Icon(
            Icons.fit_screen,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    });
  }
}

// Additional widget to show current location button
class CurrentLocationButton extends StatelessWidget {
  final LocationService locationService;
  final MapService mapService;

  const CurrentLocationButton({
    Key? key,
    required this.locationService,
    required this.mapService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () async {
          // Get current location and center map
          await locationService.getCurrentLocation();

          if (locationService.currentLatLng.value != null) {
            await mapService.animateToLocation(
              locationService.currentLatLng.value!,
              zoom: 17.0,
            );

            Get.snackbar(
              'Current Location',
              'Map centered on your location',
              duration: const Duration(seconds: 2),
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        backgroundColor: Colors.blue,
        child: Obx(() {
          if (locationService.isLocationLoading.value) {
            return const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          }

          return const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          );
        }),
      ),
    );
  }
}