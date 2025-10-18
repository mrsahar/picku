import 'package:flutter/material.dart';

Widget ratingWidget(BuildContext context) {
  var brightness = MediaQuery.of(context).platformBrightness;
  final isDarkMode = brightness == Brightness.dark;
  final inputBorderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: isDarkMode
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface, // Using surface for both dark and light themes
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6) // Dark shadow
              : Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3), // Light shadow
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
        // Profile Picture and Rating
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6), // Using onSurface for dark overlay
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

        // Driver's Name
        Text(
          "Akshay Kumar",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: isDarkMode
                ? Theme.of(context).textTheme.bodySmall?.color
                : Theme.of(context).textTheme.headlineSmall?.color, // Using theme text colors
          ),
        ),
        const SizedBox(height: 8.0),

        // Rating Stars - Centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the stars
          children: List.generate(5, (index) {
            return Icon(
              index < 4
                  ? Icons.star
                  : Icons.star_border, // Solid star for ratings and empty star for others
              color: Colors.amber,
              size: 24.0,
            );
          }),
        ),
        const SizedBox(height: 4.0),

        // Rating Text
        Text(
          "You rated 4 stars to Akshay",
          style: TextStyle(
            fontSize: 14.0,
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, // Using bodyText2 color
          ),
        ),
        const SizedBox(height: 16.0),

        // Compliment Input
        TextFormField(
          decoration: InputDecoration(
            labelText: "Give a compliment",
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit, color: Theme.of(context).iconTheme.color), // Icon color from theme
          ),
        ),
        const SizedBox(height: 16.0),

        // Tip Section
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Add a tip to Akshay?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Theme.of(context).textTheme.bodySmall?.color, // Text color from theme
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Tip Options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Predefined Tip 5
            _tipButton(context,"\$ 5", onTap: () {
              // Handle tip action
            }),
            // Predefined Tip 10 (selected)
            _tipButton(context,"\$ 10", isSelected: true, onTap: () {
              // Handle tip action
            }),
            _tipButton(context,"\$ 20", onTap: () {
              // Handle tip action
            }),
            // Predefined Tip 50
            _tipButton(context,"\$ 50", onTap: () {
              // Handle tip action
            }),
          ],
        ),
        const SizedBox(height: 16.0),

        // Custom Tip
        TextField(
          decoration: InputDecoration(
            labelText: "Enter Custom Amount",
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.money, color: Theme.of(context).iconTheme.color), // Icon color from theme
          ),
        ),
        const SizedBox(height: 24.0),

        // Done Button
        SizedBox(
          width: double.infinity, // Make button take full width
          child: ElevatedButton(
            onPressed: () {
              // Handle done action
            },
            style: ElevatedButton.styleFrom( // Button color from theme
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text("Done"),
          ),
        ),
      ],
    ),
  );
}

// Helper method to create tip buttons
Widget _tipButton(BuildContext context,String text, {bool isSelected = false, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary.withValues(alpha:0.1), // Primary color when selected
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color, // Text color from theme
          fontSize: 16.0,
        ),
      ),
    ),
  );
}

