import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';
import 'package:pick_u/utils/theme/mcolors.dart';

class ScheduledRideWidget extends StatelessWidget {
  const ScheduledRideWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RideBookingController>();

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Calendar icon with checkmark
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: MColor.primaryNavy.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 50,
              color: MColor.primaryNavy,
            ),
          ),

          const SizedBox(height: 24),

          // Status text
          Text(
            'Ride Scheduled',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Scheduled date and time
          Obx(() {
            final scheduledDateTime = controller.getScheduledDateTime();
            if (scheduledDateTime != null) {
              return Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledDateTime),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: MColor.primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 24),

          // Route information
          Obx(() {
            final pickup = controller.pickupLocation.value?.address ?? controller.pickupText.value;
            final dropoff = controller.dropoffLocation.value?.address ?? controller.dropoffText.value;

            if (pickup.isEmpty && dropoff.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Pickup location
                  if (pickup.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: MColor.primaryNavy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickup,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (dropoff.isNotEmpty) const SizedBox(height: 16),
                  ],
                  // Dropoff location
                  if (dropoff.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: MColor.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dropoff,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MColor.primaryNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: MColor.primaryNavy.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: MColor.primaryNavy,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your ride has been scheduled. A driver will be assigned closer to your scheduled time.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Loading indicator (shown instead of cancel button during booking)
          Obx(() {
            if (controller.isLoading.value) {
              return SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: MColor.primaryNavy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MColor.primaryNavy.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(MColor.primaryNavy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Scheduling your ride...',
                        style: TextStyle(
                          fontSize: 16,
                          color: MColor.primaryNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
