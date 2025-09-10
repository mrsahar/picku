// Add this widget to show driver tracking status
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/core/location_service.dart';
import 'package:pick_u/core/map_service.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

// class DriverTrackingControlsWidget extends StatelessWidget {
//   final RideBookingController controller;
//
//   const DriverTrackingControlsWidget({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       // Only show when driver is assigned and location is active
//       if (controller.rideStatus.value != RideStatus.driverAssigned &&
//           controller.rideStatus.value != RideStatus.tripStarted) {
//         return const SizedBox.shrink();
//       }
//
//       if (!controller.isDriverLocationActive.value) {
//         return const SizedBox.shrink();
//       }
//
//       return Positioned(
//         top: 100,
//         right: 16,
//         child: Column(
//           children: [
//             // Center on Driver button
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   Icons.my_location,
//                   color: MColor.primaryNavy,
//                   size: 22,
//                 ),
//                 onPressed: () => controller.centerOnDriverLocation(),
//                 tooltip: 'Center on Driver',
//                 padding: const EdgeInsets.all(8),
//               ),
//             ),
//             const SizedBox(height: 8),
//
//             // Driver info card (compact)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         'Live',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     controller.getFormattedDistanceToDriver(),
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
// }