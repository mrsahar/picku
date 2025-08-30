import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/common/dark_map_theme.dart';
import 'package:pick_u/common/light_map_theme.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/taxi/main/home/widget/destination_select_widget_state.dart';
import 'package:pick_u/taxi/main/home/widget/driver_info_widget.dart';
import 'package:pick_u/taxi/main/home/widget/location_widget.dart';
import 'package:pick_u/taxi/main/home/widget/on_trip_widget.dart';
import 'package:pick_u/taxi/main/home/widget/rating_widget.dart';
import 'package:pick_u/taxi/main/home/widget/reached_destination.dart';
import 'package:pick_u/taxi/ride_booking_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final RideController rideController = Get.put(RideController());
  late RideBookingController bookingController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(31.8329711, 70.9028416),
    zoom: 14,
  );

  bool isShowingLocationWidget = true;
  int isWidget = 0;

  @override
  void initState() {
    super.initState();
    // Try to find existing controller or create new one
    try {
      bookingController = Get.find<RideBookingController>();
    } catch (e) {
      bookingController = Get.put(RideBookingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    //final size = MediaQuery.sizeOf(context);
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    final List<Widget> widgets = [
      EnhancedDestinationWidget(), // Enhanced with functionality
      EnhancedDestinationSelectWidget(), // Enhanced with functionality
      onTripWidget(context),
      driverInfoWidget(context),
      destinationReachedWidget(context),
      ratingWidget(context),
    ];

    return Stack(
      children: [
        // Google Map with markers and polylines
        Obx(() {
          // Combine markers from both controllers
          Set<Marker> allMarkers = {};
          allMarkers.addAll(rideController.markers);
          allMarkers.addAll(bookingController.markers);

          return GoogleMap(
            mapType: MapType.normal,
            style: (isDarkMode) ? darkMapTheme : lightMapTheme,
            initialCameraPosition: _kGooglePlex,
            myLocationButtonEnabled: true,
            markers: allMarkers,
            polylines: bookingController.polylines.toSet(),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              rideController.setMapController(controller);
              // Fit map when ride is booked
              if (bookingController.isRideBooked.value) {
                _fitMapToShowAllMarkers(controller);
              }
            },
            onTap: rideController.onMapTap,
          );
        }),

        // Conditional Bottom Content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Obx(() {
            // Check if ride is booked in RideBookingController
            if (bookingController.isRideBooked.value) {
              return _buildRideActionButtons(context, bookingController);
            }

            // Otherwise show normal animated switcher
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: widgets[isWidget],
            );
          }),
        ),

        // Toggle button
        Positioned(
          top: 30,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: toggleLocationWidget,
          ),
        ),

        // Clear booking button (when ride is booked)
        Positioned(
          top: 80,
          right: 0,
          child: Obx(() {
            if (bookingController.isRideBooked.value) {
              return IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () {
                  bookingController.clearBooking();
                  Get.snackbar('Cleared', 'Ride booking cleared');
                },
                tooltip: 'Clear Route',
              );
            }
            return const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  Widget _buildRideActionButtons(BuildContext context, RideBookingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.pickupController.text,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.dropoffController.text,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (controller.additionalStops.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${controller.additionalStops.where((stop) => stop.address.isNotEmpty).length} additional stop(s)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Get.to(() => RideBookingPage()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit_location_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Edit'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: controller.startRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Ride'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _fitMapToShowAllMarkers(GoogleMapController controller) async {
    // Wait a bit for markers to be rendered
    await Future.delayed(const Duration(milliseconds: 500));

    if (bookingController.markers.isEmpty) return;

    List<LatLng> markerPositions = bookingController.markers
        .map((marker) => marker.position)
        .toList();

    if (markerPositions.length == 1) {
      // If only one marker, center on it
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: markerPositions.first,
            zoom: 15,
          ),
        ),
      );
      return;
    }

    // Calculate bounds for multiple markers
    double minLat = markerPositions.first.latitude;
    double maxLat = markerPositions.first.latitude;
    double minLng = markerPositions.first.longitude;
    double maxLng = markerPositions.first.longitude;

    for (LatLng position in markerPositions) {
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLng = math.min(minLng, position.longitude);
      maxLng = math.max(maxLng, position.longitude);
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void toggleLocationWidget() {
    setState(() {
      isWidget = (isWidget + 1) % 6;
    });
  }
}


