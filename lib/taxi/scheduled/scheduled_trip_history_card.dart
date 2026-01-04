import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/controllers/scheduled_ride_history_controller.dart';
import 'package:pick_u/models/scheduled_ride_history_model.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class ScheduledTripHistoryCard extends StatelessWidget {
  const ScheduledTripHistoryCard({
    super.key,
    required this.ride,
    this.controller,
  });

  final ScheduledRideItem ride;
  final ScheduledRideHistoryController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Scheduled Date and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MColor.primaryNavy.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: MColor.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scheduled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ride.formattedScheduledDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ride.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ride.statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ride.status.toUpperCase(),
                        style: TextStyle(
                          color: ride.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Route Information
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      ride.formattedScheduledTime,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        Container(
                          height: 30,
                          width: 2,
                          color: theme.dividerColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(
                      ride.shortPickupLocation,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ),
                ],
              ),
              // End Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '', // No end time for scheduled rides
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(
                      ride.shortDropoffLocation,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ),
                ],
              ),

                const SizedBox(height: 16),

                // Metadata Row
                Row(
                  children: [
                    // Created At
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                DateFormat('dd MMM, HH:mm').format(ride.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Driver Assignment
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'No driver assigned',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer: Fare and Cancel Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cancel button (only show when status is "Waiting" or "Pending")
                    if ((ride.status.toLowerCase() == 'waiting' || ride.status.toLowerCase() == 'pending') && controller != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller!.isLoading
                              ? null
                              : () => _showCancelConfirmationDialog(context),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MColor.danger,
                            side: BorderSide(color: MColor.danger, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if ((ride.status.toLowerCase() == 'waiting' || ride.status.toLowerCase() == 'pending') && controller != null)
                      const SizedBox(width: 12),
                    // Price always on the right
    Text(
    '\$${ride.fareFinal.toStringAsFixed(2)}',
    style: theme.textTheme.titleMedium!.copyWith(
    color: theme.colorScheme.primary,
    fontWeight: FontWeight.bold,
    ),
    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Ride'),
          content: const Text('Are you sure you want to cancel this scheduled ride?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (controller != null) {
                  // Use rideId if available, otherwise we'll need to handle it in the controller
                  if (ride.rideId != null && ride.rideId!.isNotEmpty) {
                    controller!.cancelRide(ride.rideId!);
                  } else {
                    // Show error if rideId is missing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Ride ID not found. Cannot cancel ride.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: MColor.danger,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}