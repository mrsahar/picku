import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:pick_u/controllers/ride_controller.dart';
// TODO remove
class DestinationSelectWidget extends StatelessWidget {
  final RideController rideController = Get.find<RideController>();

  DestinationSelectWidget({Key? key}) : super(key: key);

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
          Text(
            'Choose Ride Type',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRideOptionCard(
                  context: context,
                  icon: LineAwesomeIcons.car_alt_solid,
                  title: 'One Stop Ride',
                  isSelected: !rideController.isMultiStopRide.value,
                  onTap: () {
                    rideController.setRideType('One Stop Ride');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('One Stop Ride selected')),
                    );
                  },
                ),
                _buildRideOptionCard(
                  context: context,
                  icon: LineAwesomeIcons.route_solid,
                  title: 'Multi-Stop Ride',
                  isSelected: rideController.isMultiStopRide.value,
                  onTap: () {
                    rideController.setRideType('Multi-Stop Ride');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Multi-Stop Ride selected')),
                    );
                  },
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          // Passenger count selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inputBorderColor!),
            ),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Passengers:', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      onPressed: rideController.decrementPassengers,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${rideController.passengerCount.value}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: rideController.incrementPassengers,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          // Book ride button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: rideController.isLoading.value
                  ? null
                  : () => rideController.bookRide(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: rideController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Book Ride',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )),
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

