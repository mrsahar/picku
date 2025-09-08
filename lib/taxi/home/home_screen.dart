import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/core/map_service.dart';
import 'package:pick_u/taxi/booking/no_drivers_available_widget.dart';
import 'package:pick_u/taxi/booking/waiting_for_driver_widget.dart';
import 'package:pick_u/taxi/home/widget/driver_info_widget.dart';
import 'package:pick_u/taxi/home/widget/location_widget.dart';
import 'package:pick_u/taxi/ride_booking_page.dart';
import 'package:pick_u/utils/map_theme/dark_map_theme.dart';
import 'package:pick_u/utils/map_theme/light_map_theme.dart';
import 'package:pick_u/widget/driver_tracking_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  // Inject services
  late RideBookingController bookingController;
  late LocationService locationService;
  late MapService mapService;

  bool _hasInitialLocationBeenSet = false;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(31.8329711, 70.9028416),
    zoom: 14,
  );

  bool isShowingLocationWidget = true;
  int isWidget = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeLocation();
    _setupLocationListener();
  }

  void _initializeServices() {
    // Get services from dependency injection
    try {
      bookingController = Get.find<RideBookingController>();
      locationService = Get.find<LocationService>();
      mapService = Get.find<MapService>();
    } catch (e) {
      // Fallback - create services if not found
      bookingController = Get.put(RideBookingController());
      locationService = Get.find<LocationService>();
      mapService = Get.find<MapService>();
    }
  }

  Future<void> _initializeLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Use LocationService instead of controller method
      await locationService.getCurrentLocation();
      print(' SAHAr Location initialized successfully');
    } catch (e) {
      print(' SAHAr Error initializing location: $e');
    }
  }

  void _setupLocationListener() {
    // Set up location listener early to catch all location updates
    ever(locationService.currentLatLng, (LatLng? newLocation) {
      if (newLocation != null) {
        print(' SAHAr Location updated: $newLocation');

        // Add user location marker using the custom user.png marker
        mapService.updateUserLocationMarker(
          newLocation.latitude,
          newLocation.longitude,
          title: 'Your Location',
        );

        // Center map on first location update
        if (!_hasInitialLocationBeenSet) {
          _centerMapToLocation(newLocation, zoom: 17.0);
          _hasInitialLocationBeenSet = true;
        }
      }
    });

    // Also check if location is already available (in case listener misses initial update)
    if (locationService.currentLatLng.value != null) {
      print(' SAHAr Location already available: ${locationService.currentLatLng.value}');
      mapService.updateUserLocationMarker(
        locationService.currentLatLng.value!.latitude,
        locationService.currentLatLng.value!.longitude,
        title: 'Your Location',
      );

      if (!_hasInitialLocationBeenSet) {
        _centerMapToLocation(locationService.currentLatLng.value!, zoom: 17.0);
        _hasInitialLocationBeenSet = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    final List<Widget> widgets = [
      EnhancedDestinationWidget(
        onCenterMap: _centerMapToLocation,
      ),
    ];

    return Stack(
      children: [
        Obx(() {
          print(' SAHAr Rebuilding map with ${mapService.markers.length} markers');
          return Padding(
            padding: const EdgeInsets.only(bottom: 180.0),
            child: GoogleMap(
              mapType: MapType.normal,
              style: (isDarkMode) ? darkMapTheme : lightMapTheme,
              initialCameraPosition: _kGooglePlex,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              markers: mapService.markers.toSet(), // Use MapService markers
              polylines: mapService.polylines.toSet(), // Use MapService polylines
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                mapService.setMapController(controller); // Set controller in MapService

                // Fit map when ride is booked
                if (bookingController.isRideBooked.value) {
                  _fitMapToShowAllMarkers();
                }
              },
            ),
          );
        }),

        // Bottom widgets based on ride status
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Obx(() {
            print('SAHAr Current ride status: ${bookingController.rideStatus.value}');

            switch (bookingController.rideStatus.value) {
              case RideStatus.waiting:
                return const WaitingForDriverWidget();
              case RideStatus.noDriver:
                return const NoDriversAvailableWidget();
              case RideStatus.driverAssigned:
              case RideStatus.tripStarted:
                return driverInfoWidget(context);

              case RideStatus.tripCompleted:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  bookingController.clearBooking();
                });

                // Show the initial destination widget as if app just started
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

              case RideStatus.cancelled:
                return const NoDriversAvailableWidget();

              case RideStatus.booked:
                if (bookingController.isRideBooked.value) {
                  return _buildRideActionButtons(context, bookingController);
                }
                break;

              case RideStatus.pending:
              default:
              // Default fallback - show initial destination widget (like new app started)
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
            }

            // Fallback return (shouldn't reach here but good practice)
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
                      color: Colors.black.withValues(alpha: 0.1),
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

        // Show pickup location button (when pickup is set but not booked)
        Positioned(
          top: 40,
          right: 16,
          child: Obx(() {
            if (bookingController.pickupLocation.value != null &&
                !bookingController.isRideBooked.value) {
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
                  icon: Icon(Icons.my_location, color: Colors.blue, size: 22),
                  onPressed: () => mapService.showPickupLocationWithZoom(
                    bookingController.pickupLocation.value,
                  ), // Use MapService method
                  tooltip: 'Show Pickup Location',
                  padding: const EdgeInsets.all(8),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ),

        // Loading indicator - use LocationService loading state
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Obx(() {
            if (locationService.isLocationLoading.value &&
                locationService.currentAddress.value.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Getting your location...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ),

        // Driver tracking widgets (updated to use new architecture)
        DriverTrackingWidget(controller: bookingController),
        FitMapButton(controller: bookingController, mapService: mapService),
      ],
    );
  }

  // Enhanced method using MapService
  Future<void> _centerMapToLocation(LatLng location, {double zoom = 16.0}) async {
    await mapService.animateToLocation(location, zoom: zoom);
    print(' SAHAr Map centered to: $location with zoom: $zoom');
  }

  // Updated to use MapService
  Future<void> _fitMapToShowAllMarkers() async {
    if (mapService.markers.isEmpty) return;

    List<LatLng> markerPositions = mapService.markers
        .map((marker) => marker.position)
        .toList();

    await mapService.fitMapToLocations(markerPositions);
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
                      color: Colors.blue,
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
                      color: Colors.blue,
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

                // Show route info from MapService
                Obx(() {
                  if (mapService.routeDistance.value.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            '📍 ${mapService.routeDistance.value}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            '⏱️ ${mapService.routeDuration.value}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
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
                  child: Obx(() => controller.isLoading.value
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(controller.isScheduled.value ? 'Schedule It' : 'Start Ride')
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void toggleLocationWidget() {
    setState(() {
      isWidget = (isWidget + 1) % 6;
    });
  }
}
