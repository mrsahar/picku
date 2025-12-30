import 'package:flutter/material.dart';
import 'package:pick_u/models/ride_history_model.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({
    super.key,
    required this.ride,
  });

  final RideItem ride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ride.formattedDate,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                    ),
                  ),
                  Text(
                    ride.status.toUpperCase(),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: MColor.primaryNavy,
                      fontWeight: FontWeight.bold,
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
                      ride.formattedStartTime,
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
                      ride.formattedEndTime,
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

