import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class SelectCarPage extends StatelessWidget {
  const SelectCarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold( appBar: AppBar(
        leading: IconButton(onPressed: (){} ,
            icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: Text("Select Car",  style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select the vehicle category you want to ride.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                VehicleOption(
                  icon: Icons.directions_bike,
                  title: "Bike",
                  subtitle: "7 nearbies",
                  price: "\$10.00",
                  isSelected: true,
                ),
                VehicleOption(
                  icon: Icons.directions_car,
                  title: "Standard",
                  subtitle: "9 nearbies",
                  price: "\$20.00",
                  isSelected: false,
                ),
                VehicleOption(
                  icon: Icons.local_taxi,
                  title: "Premium",
                  subtitle: "4 nearbies",
                  price: "\$30.00",
                  isSelected: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;

  const VehicleOption({super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                price,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoTile({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
    color: theme.colorScheme.onPrimary,)
        ),
      ],
    );
  }
}
