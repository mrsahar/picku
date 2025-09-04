import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/ride_history_controller.dart';
import 'package:pick_u/taxi/history/widget/trip_card_widget.dart';
import 'package:pick_u/taxi/history/widget/trip_summary_widget.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class RideHistoryPage extends GetView<RideHistoryController> {
  const RideHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: const Text(
          "Trip History",
          style: TextStyle(fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.rideHistory == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.rideHistory == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchRideHistory,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshHistory,
          child: Column(
            children: [
              // Header Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Trips
                    Expanded(
                      child: SummaryWidget(
                        title: "Total trips",
                        value: controller.totalRides.toString(),
                        icon: Icons.directions_car,
                        iconColor: MColor.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Completed Trips
                    Expanded(
                      child: SummaryWidget(
                        title: "Finished",
                        value: controller.completedRides.toString(),
                        icon: Icons.check_circle,
                        iconColor: MColor.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Canceled Trips
                    Expanded(
                      child: SummaryWidget(
                        title: "Cost",
                        value: '₹${controller.totalFare.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet,
                        iconColor: MColor.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),


              const Divider(),

              // Trip List
              Expanded(
                child: controller.rides.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ride history found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: controller.rides.length,
                  itemBuilder: (context, index) {
                    final ride = controller.rides[index];
                    return TripHistoryCard(ride: ride);
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

