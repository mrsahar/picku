import 'package:flutter/material.dart';

import '../../../../utils/theme/mcolors.dart';
// TODO remove
Widget destinationReachedWidget(BuildContext context) {
  final theme = Theme.of(context);

  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // From theme
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              blurRadius: 10.0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You Reached Destination",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // Driver Info
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const CircleAvatar(
                      radius: 36.0,
                      backgroundImage: AssetImage("assets/img/u2.png"),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: MColor.trackingOrange, size: 14.0),
                            const SizedBox(width: 2),
                            const Text(
                              "4.5",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Akshay Kumar",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),

            const Divider(),

            // Route Info
            Column(
              children: [
                _buildTripRouteItem(
                  context: context,
                  icon: Icons.circle,
                  color: theme.colorScheme.primary,
                  title: "SkyHeights Apartment",
                  time: "11:20 AM",
                ),
                const SizedBox(height: 16.0),
                _buildTripRouteItem(
                  context: context,
                  icon: Icons.location_on,
                  color: MColor.trackingOrange,
                  title: "Mantri Square Mall",
                  time: "11:45 AM",
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
Widget _buildTripRouteItem({
  required BuildContext context,
  required IconData icon,
  required Color color,
  required String title,
  required String time,
}) {
  final theme = Theme.of(context);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 4.0),
        child: Icon(
          icon,
          color: color,
          size: 16.0,
        ),
      ),
      const SizedBox(width: 8.0),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            Divider(
              height: 1,
              color: theme.dividerColor,
            ),
          ],
        ),
      ),
      Text(
        time,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: MColor.trackingOrange, // Can also be colorScheme.secondary
        ),
      ),
    ],
  );
}