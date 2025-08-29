import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pick_u/controllers/ride_booking_controller.dart';

class RideBookingPage extends StatelessWidget {
  final RideBookingController controller = Get.put(RideBookingController());

  RideBookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        elevation: 0,
      ),
      body: _buildLocationInputView(context),
    );
  }

  Widget _buildLocationInputView(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup Location
          Text(
            'Pickup Location',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildLocationTextField(
                  controller: controller.pickupController,
                  hintText: 'Enter pickup location',
                  icon: Icons.my_location,
                  onChanged: (value) => controller.searchLocation(value, 'pickup'),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () async {
                  await controller.getCurrentLocation();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.gps_fixed, color: Colors.white),
              )),
            ],
          ),

          const SizedBox(height: 16),

          // Dropoff Location
          Text(
            'Dropoff Location',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLocationTextField(
            controller: controller.dropoffController,
            hintText: 'Enter dropoff location',
            icon: Icons.location_on,
            onChanged: (value) => controller.searchLocation(value, 'dropoff'),
          ),

          // Additional Stops
          Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.stopControllers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Additional Stops',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...controller.stopControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stopController = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildLocationTextField(
                              controller: stopController,
                              hintText: 'Stop ${index + 1}',
                              icon: Icons.add_location,
                              onChanged: (value) => controller.searchLocation(value, 'stop_$index'),
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.removeStop(index),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            );
          }),

          // Add Stop Button
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.addStop,
            icon: const Icon(Icons.add),
            label: const Text('Add Stop'),
          ),

          // Search Suggestions
          Obx(() {
            if (controller.searchSuggestions.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = controller.searchSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(suggestion),
                      onTap: () => controller.selectSuggestion(suggestion),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 24),

          // Passenger Count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Passengers:', style: TextStyle(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (controller.passengerCount.value > 1) {
                          controller.passengerCount.value--;
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${controller.passengerCount.value}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        if (controller.passengerCount.value < 8) {
                          controller.passengerCount.value++;
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            )),
          ),

          const SizedBox(height: 24),

          // Book Ride Button
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () async {
                await controller.bookRide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Book Ride',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}