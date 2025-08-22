import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/common/extension.dart';
import 'package:pick_u/taxi/main/search/search_location.dart';

class DestinationWidget extends StatefulWidget {
  @override
  _DestinationWidgetState createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    // Get theme data
    final theme = Theme.of(context);

    // Data for locations
    final List<Map<String, dynamic>> locations = [
      {
        'icon': LineAwesomeIcons.map_marker_alt_solid,
        'title': 'Book a Ride',
        'subtitle': 'Enter Destination'
      },
      {'icon': LineAwesomeIcons.briefcase_solid, 'title': 'Office', 'subtitle': '35 Km Away'},
      {'icon': LineAwesomeIcons.home_solid, 'title': 'Home', 'subtitle': '12 Km Away'},
      {'icon': LineAwesomeIcons.tree_solid, 'title': 'Park', 'subtitle': '8 Km Away'},
    ];
    final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    return Container(
      color: theme.colorScheme.surface, // Background color from theme
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
                  // Handle click action here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule clicked!'),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Adjusts to content size
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LineAwesomeIcons.history_solid, // Add your desired icon
                      color: theme.colorScheme.primary, // Use primary color
                      size: 20, // Icon size
                    ),
                    const SizedBox(width: 5), // Space between icon and text
                    Text(
                      'Schedule',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,  // Make it stand out
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable area
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, // White scroller background
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
                      isHighlighted: index == 0, // Highlight first item
                    ),
                  );
                }).toList(),
              ),
            ),
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
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      color: isHighlighted
          ? theme.colorScheme.primary // Highlight color for first item
          : theme.colorScheme.surface, // Normal card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push(const SearchLocation());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with rounded white background
              Container(
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? theme.colorScheme.onPrimary
                      : theme
                          .colorScheme.secondary, // White background for icon
                  shape: BoxShape.circle, // Circular shape
                ),
                padding: const EdgeInsets.all(12), // Padding around the icon
                child: Icon(
                  icon,
                  size: 24,
                  color: isHighlighted
                      ? theme.colorScheme.primary // Icon color for highlighted
                      : theme
                          .colorScheme.onPrimary, // Icon color for normal state
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
