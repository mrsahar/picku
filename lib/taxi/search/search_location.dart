import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/widget/picku_appbar.dart';

class SearchLocation extends StatelessWidget {
  const SearchLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PickUAppBar(
        title: "Search Location",
        onBackPressed: () {
          // Your custom back logic
          Get.back();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup Location Input Section
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const VerticalRouteIndicator(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Pickup Location",
                            labelStyle: theme.textTheme.bodyMedium,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Destination",
                            labelStyle: theme.textTheme.bodyMedium,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Saved Places Section
            Card(
              child: ListTile( 
                tileColor: theme.colorScheme.surface,
                leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                title: Text(
                  "Saved Places",
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  // Handle navigation to saved places
                },
              ),
            ),
            const SizedBox(height: 24.0),

            // Suggested Locations Title
            Text(
              "Suggested Locations",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),

            // Suggested Locations List
            Expanded(
              child: ListView.builder(
                itemCount: 10, // For demonstration
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      Icons.location_pin,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text("Location ${index + 1}", style: theme.textTheme.bodyMedium),
                    subtitle: Text("Address details for Location ${index + 1}"),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You selected Location ${index + 1}!"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerticalRouteIndicator extends StatelessWidget {
  const VerticalRouteIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Circle
        Icon(Icons.radio_button_checked,size: 24,
            color: Theme.of(context).colorScheme.secondary),
        // Dotted Line
        CustomPaint(
          size: const Size(2, 60),
          painter: DottedLinePainter(),
        ),
        // Bottom Circle (Location Marker)
        Icon(
          Icons.location_on,
          size: 24,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    double dashHeight = 5, dashSpace = 5, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(1, startY),
        Offset(1, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}