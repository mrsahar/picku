import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/taxi/main/home/widget/destination_select_widget_state.dart';
import 'package:pick_u/taxi/main/home/widget/driver_info_widget.dart';
import 'package:pick_u/taxi/main/home/widget/location_widget.dart';
import 'package:pick_u/taxi/main/home/widget/on_trip_widget.dart';
import 'package:pick_u/taxi/main/home/widget/rating_widget.dart';
import 'package:pick_u/taxi/main/home/widget/reached_destination.dart';

import '../../../../common/dark_map_theme.dart';
import '../../../../common/light_map_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  late GoogleMap googleMap;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(31.8329711, 70.9028416),
    zoom: 14,
  );
  bool isShowingLocationWidget = true;
  int isWidget = 0;



  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final size = MediaQuery.sizeOf(context);
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    final List<Widget> widgets = [
      DestinationWidget(),
      DestinationSelectWidget(),
      onTripWidget(context),
      driverInfoWidget(context),
      destinationReachedWidget(context),
      ratingWidget(context),
    ];
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          mapType: MapType.normal,
          style: (isDarkMode) ? darkMapTheme : lightMapTheme,
          initialCameraPosition: _kGooglePlex,
          myLocationButtonEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        // Custom Bottom Sheet with AnimatedSwitcher
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500), // Transition duration
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0), // Start from below the view
                  end: Offset.zero, // End at the current position
                ).animate(animation),
                child: child,
              );
            },
            child: widgets[isWidget],
          ),
        ),
        Positioned(
          top: 30,
            right: 0,
            child: IconButton(
          icon: Icon(Icons.swap_horiz),
          onPressed: toggleLocationWidget,
        ))
      ],
    );
  }

  // Toggle between widgets
  void toggleLocationWidget() {
    setState(() {
      // Cycle through widget indices
      isWidget = (isWidget + 1) % 6; // Assuming you have 4 widgets in the list
    });
  }
}

