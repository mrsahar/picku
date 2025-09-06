import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/utils/map_theme/dark_map_theme.dart';
import 'package:pick_u/utils/map_theme/light_map_theme.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/taxi/booking/no_drivers_available_widget.dart';
import 'package:pick_u/taxi/booking/waiting_for_driver_widget.dart';
import 'package:pick_u/taxi/home/widget/driver_info_widget.dart';
import 'package:pick_u/taxi/home/widget/location_widget.dart';
import 'package:pick_u/taxi/ride_booking_page.dart';
import 'package:pick_u/utils/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  //final RideController rideController = Get.lazyPut(() =>RideController());
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
      EnhancedDestinationWidget(),
      //driverInfoWidget(context),
      //ratingWidget(context),
    ];

    return Stack(
      children: [
        // Google Map with markers and polylines
        Obx(() {
          // Combine markers from both controllers
          Set<Marker> allMarkers = {};
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
              // Fit map when ride is booked
              if (bookingController.isRideBooked.value) {
                _fitMapToShowAllMarkers(controller);
              }
            },
          );
        }),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Obx(() {
            // Check ride status to show appropriate widget
            if (bookingController.rideStatus.value == 'waiting') {
              return const WaitingForDriverWidget();
            } else if (bookingController.rideStatus.value == 'driver_assigned' ||
                bookingController.rideStatus.value == 'driver_on_way' ||
                bookingController.rideStatus.value == 'trip_started') { // Add this line
              return driverInfoWidget(context);
            } else if (bookingController.rideStatus.value == 'no_driver') {
              return const NoDriversAvailableWidget();
            } else if (bookingController.isRideBooked.value) {
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

        // Clear booking button (when ride is booked)
        Positioned(
          top: 40,
          right: 16,
          child: Obx(() {
            if (bookingController.isRideBooked.value) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red, size: 22),
                  onPressed: () {
                    bookingController.clearBooking();
                    Get.snackbar('Cleared', 'Ride booking cleared');
                  },
                  tooltip: 'Clear Route',
                  padding: const EdgeInsets.all(8),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  Widget _buildRideActionButtons(
    BuildContext context,
    RideBookingController controller,
  ) {
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
                    Icon(
                      Icons.location_on,
                      color: MAppTheme.primaryNavyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.pickupController.text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: MAppTheme.primaryNavyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.dropoffController.text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                  child: Obx(() => Text(bookingController.isScheduled.value ? 'Schedule It' : 'Start Ride')),
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
          CameraPosition(target: markerPositions.first, zoom: 15),
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

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  void toggleLocationWidget() {
    setState(() {
      isWidget = (isWidget + 1) % 6;
    });
  }
}
