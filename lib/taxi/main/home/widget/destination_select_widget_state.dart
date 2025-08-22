import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class DestinationSelectWidget extends StatefulWidget {
  const DestinationSelectWidget({super.key});

  @override
  State<DestinationSelectWidget> createState() => _DestinationSelectWidgetState();
}

class _DestinationSelectWidgetState extends State<DestinationSelectWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isDarkMode = mediaQuery.platformBrightness == Brightness.dark;
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar indicator
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
          const SizedBox(height: 16),
          // Title
          Text(
            'Choose Ride Type',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),

          // Scrollable row of two card-style buttons
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRideOptionCard(
                  context: context,
                  icon: LineAwesomeIcons.car_alt_solid,
                  title: 'One Stop Ride',
                  isSelected: true,
                  onTap: () {
                    // TODO: Add your action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('One Stop Ride selected')),
                    );
                  },
                ),
                _buildRideOptionCard(
                  context: context,
                  icon: LineAwesomeIcons.route_solid,
                  title: 'Multi-Stop Ride',
                  isSelected: false,
                  onTap: () {
                    // TODO: Add your action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Multi-Stop Ride selected')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        elevation: 2,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with circular background
                Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

