import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/ride_controller.dart';
import 'package:pick_u/taxi/ride_booking_page.dart';

class EnhancedDestinationWidget extends StatelessWidget {
  final RideController rideController = Get.find<RideController>();

  EnhancedDestinationWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    final theme = Theme.of(context);
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    // Data for locations with enhanced functionality
    final List<Map<String, dynamic>> locations = [
      {
        'icon': LineAwesomeIcons.map_marker_alt_solid,
        'title': 'Book a Ride',
        'subtitle': 'Enter Destination',
         'action': () => Get.to(() => RideBookingPage()),
      },
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: inputBorderColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Where to?',
                style: theme.textTheme.titleSmall,
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule clicked!')),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LineAwesomeIcons.history_solid,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Schedule',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: locations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final location = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildDestinationCard(
                      context: context,
                      icon: location['icon'],
                      title: location['title'],
                      subtitle: location['subtitle'],
                      isHighlighted: index == 0,
                      onTap: location['action'],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Current location display
          Obx(() => rideController.currentAddress.value.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current: ${rideController.currentAddress.value}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: isHighlighted
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  size: 24,
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
