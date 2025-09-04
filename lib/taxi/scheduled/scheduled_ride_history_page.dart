import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/scheduled_ride_history_controller.dart';
import 'package:pick_u/taxi/history/widget/trip_summary_widget.dart';
import 'package:pick_u/taxi/scheduled/scheduled_trip_history_card.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class ScheduledRideHistoryPage extends GetView<ScheduledRideHistoryController> {
  const ScheduledRideHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: const Text(
          "Scheduled Rides",
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.scheduledRideHistory == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.scheduledRideHistory == null) {
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
                  onPressed: controller.fetchScheduledRideHistory,
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Total Rides
                    Expanded(
                      child: SummaryWidget(
                        title: "Scheduled",
                        value: controller.totalRides.toString(),
                        icon: Icons.schedule,
                        iconColor: MColor.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Pending Rides
                    Expanded(
                      child: SummaryWidget(
                        title: "Pending",
                        value: controller.pendingRides.toString(),
                        icon: Icons.pending,
                        iconColor: MColor.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Spent
                    Expanded(
                      child: SummaryWidget(
                        title: "Spent",
                        value: controller.totalSpentINR,
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
                        Icons.schedule,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No scheduled rides found',
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
                    return ScheduledTripHistoryCard(ride: ride);
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