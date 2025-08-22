import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/taxi/main/history/widget/trip_card_widget.dart';
import 'package:pick_u/taxi/main/history/widget/trip_summary_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: const Text(
          "Trip History",
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Header Summary
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total Trips
                Expanded(
                  child: SummaryWidget(
                    title: "Total trips",
                    value: "1005",
                    icon: Icons.directions_car,
                    iconColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                // Completed Trips
                Expanded(
                  child: SummaryWidget(
                    title: "Finished",
                    value: "1000",
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                // Canceled Trips
                Expanded(
                  child: SummaryWidget(
                    title: "Canceled",
                    value: "5",
                    icon: Icons.cancel,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Trip List
          Expanded(
            child: ListView(
              children: const [
                TripHistoryCard(
                  date: "10 June 2019, 21:53",
                  timeStart: "18:03",
                  startLocation: "1, Thrale Street, London, SE19HW, UK",
                  timeEnd: "18:44",
                  endLocation: "18, Ocean Avenue, London, SE19HW, UK",
                  status: "Cancelled",
                  statusColor: Colors.red,
                ),
                TripHistoryCard(
                  date: "09 June 2019, 20:45",
                  timeStart: "17:00",
                  startLocation: "12, King Street, Manchester, UK",
                  timeEnd: "17:45",
                  endLocation: "34, Market Road, Leeds, UK",
                  status: "Completed",
                  statusColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
