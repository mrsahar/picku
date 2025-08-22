import 'package:flutter/material.dart';

Widget driverInfoWidget(BuildContext context) {
  final theme = Theme.of(context);
  var brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.3),
              blurRadius: 10.0,
              offset: const Offset(0, -4), // Shadow at the top
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            // Title
            const Text(
              "Your Ride is arriving in 3 mins",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 8.0),

            // Divider
            Divider(color: theme.dividerColor, thickness: 0.4),
            const SizedBox(height: 16.0),

            // Driver Info Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Message Icon
                _buildCircularButton(
                  icon: Icons.message,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    // Handle message action
                  },
                ),
                // Driver Info
                Column(
                  children: [
                    // Driver Profile Picture
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CircleAvatar(
                          radius: 36.0,
                          backgroundImage: const AssetImage("assets/img/u2.png"),
                          backgroundColor: theme.cardColor,
                        ),
                        Positioned(
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14.0),
                                const SizedBox(width: 2),
                                Text(
                                  "4.5",
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),

                    // OTP and Vehicle Info
                    Column(
                      children: [
                        const SizedBox(height: 2.0),
                        Text(
                          "Swift Dezire   KA 05 EH 2567",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Call Icon
                _buildCircularButton(
                  icon: Icons.call,
                  color: theme.primaryColor,
                  isDarkMode: isDarkMode,
                  onPressed: () {
                    // Handle call action
                  },
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Share Button
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      // Handle share action
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("share"),
                  ),
                ),
                const SizedBox(width: 10.0),

                // Cancel Ride Button
                Expanded(
                  flex: 8,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                     // backgroundColor: theme.errorColor.withOpacity(0.1),
                      elevation: 0,
                     // foregroundColor: theme.errorColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      // Handle cancel ride action
                    },
                    child: const Text("Cancel Ride"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// Helper method to build circular buttons
Widget _buildCircularButton({
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
  required bool isDarkMode,
}) {
  // Adjust background color for better contrast in dark mode
  final backgroundColor = isDarkMode
      ? const Color(0xFFFFC900) // Slightly higher opacity for dark mode
      : color.withOpacity(0.2); // Lighter opacity for light mode

  return GestureDetector(
    onTap: onPressed,
    child: CircleAvatar(
      radius: 24.0,
      backgroundColor: backgroundColor,
      child: Icon(icon, color: color, size: 28.0),
    ),
  );
}
