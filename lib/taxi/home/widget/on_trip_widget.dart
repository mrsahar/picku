import 'package:flutter/material.dart';
// TODO remove
Widget onTripWidget(context) {
  var brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;

  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: isDarkMode
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface, // Both themes using surface for background
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) // Dark shadow
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3), // Light shadow
          blurRadius: 10.0,
          offset: const Offset(0, -4), // Shadow at the top
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status and Emergency Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "On Trip",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: isDarkMode
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : Theme.of(context).textTheme.headlineSmall?.color, // Text color from theme
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle emergency action
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 18.0,
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    "Emergency",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Driver Info Section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Message Icon
            _buildCircularButton(
              icon: Icons.message,
              color: Theme.of(context).primaryColor, // Using primary color from theme
              onPressed: () {
                // Handle message action
              },
            ),
            const SizedBox(width: 24.0),
            // Driver Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Driver Profile Picture and Rating
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
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.6), // Use surface for the dark background
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14.0),
                            SizedBox(width: 2),
                            Text(
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

                // Driver Name
                Text(
                  "Akshay Kumar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: isDarkMode
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : Theme.of(context).textTheme.headlineSmall?.color, // Text color from theme
                  ),
                ),
                const SizedBox(height: 4.0),

                // OTP and Vehicle Info
                const Column(
                  children: [
                    Text(
                      "Swift Dezire   KA 05 EH 2567",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 5.0),
            // Call Icon
            _buildCircularButton(
              icon: Icons.call,
              color: Theme.of(context).primaryColor, // Using primary color from theme
              onPressed: () {
                // Handle call action
              },
            ),
          ],
        ),
        const SizedBox(height: 24.0),

        // Action Buttons (Share and End Ride)
        Row(
          children: [
            // Share Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle share action
                },
                icon: const Icon(Icons.share, color: Colors.black),
                label: const Text(
                  "Share",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).buttonTheme.colorScheme?.surface, // Use surface from theme for background
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),

            // End Ride Button
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  // Handle end ride action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).buttonTheme.colorScheme?.primary, // Button color from theme
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  "End Ride",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Helper method to build circular buttons
Widget _buildCircularButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    onTap: onPressed,
    child: CircleAvatar(
      radius: 24.0,
      backgroundColor: color.withOpacity(0.2), // Color with opacity
      child: Icon(icon, color: color, size: 28.0),
    ),
  );
}



