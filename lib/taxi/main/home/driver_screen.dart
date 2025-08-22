import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: Text(
          "Driver Profile",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0,horizontal: 8.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                          'assets/img/u2.png'), // Replace with actual image
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amir Hassan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                           Text('New York, United States',
                            style: theme.textTheme.labelMedium,),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_walk,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              const Text('130+ Trips'),
                              const SizedBox(width: 16),
                              Icon(Icons.timer,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              const Text('10 Years'),
                              const SizedBox(width: 16),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 16, color: theme.colorScheme.secondary),
                              const SizedBox(width: 4),
                              const Text('4.9 Rating'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tab Section (About and Review)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(
                            text: 'About',
                          ),
                          Tab(
                            text: 'Review',
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 250, // Adjust height based on content
                        child: TabBarView(
                          children: [
                            // About Tab Content
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  const Text(
                                    'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s...',
                                  ),
                                  const SizedBox(height: 8.0),
                                  GestureDetector(
                                    onTap: () {
                                      // Handle read more action
                                    },
                                    child: Text(
                                      'Read More',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Review Tab Content
                            const Center(child: Text('Review content goes here')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Car Details Section

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Car Details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(Icons.directions_car,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Car Model: Hyundai Verna'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.confirmation_number,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Car Number: GR-678 UVWY'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.color_lens,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Car Color: White'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
