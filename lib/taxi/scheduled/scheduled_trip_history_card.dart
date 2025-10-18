import 'package:flutter/material.dart';
import 'package:pick_u/models/scheduled_ride_history_model.dart';

class ScheduledTripHistoryCard extends StatelessWidget {
  const ScheduledTripHistoryCard({
    super.key,
    required this.ride,
  });

  final ScheduledRideItem ride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scheduled Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scheduled: ${ride.formattedScheduledDate}',
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ride.statusColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: ride.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Start Location
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
              // Fare
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
    );
  }
}