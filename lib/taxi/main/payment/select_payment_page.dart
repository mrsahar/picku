import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: const Icon(LineAwesomeIcons.angle_left_solid)),
        title: Text(
          "Payment Methods",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Action for adding new payment method
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select the payment method you want to use.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                PaymentOption(
                  icon: Icons.account_balance_wallet,
                  title: "My Wallet",
                  subtitle: "\$957.50",
                  isSelected: true,
                ),
                PaymentOption(
                  icon: Icons.paypal,
                  title: "PayPal",
                  isSelected: false,
                ),
                PaymentOption(
                  icon: LineAwesomeIcons.google_play,
                  title: "Google Pay",
                  isSelected: false,
                ),
                PaymentOption(
                  icon: Icons.apple,
                  title: "Apple Pay",
                  isSelected: false,
                ),
                PaymentOption(
                  icon: Icons.credit_card,
                  title: "MasterCard",
                  subtitle: "**** **** **** 4679",
                  isSelected: false,
                ),
                PaymentOption(
                  icon: Icons.money,
                  title: "Cash Money",
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

class PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;

  const PaymentOption({super.key,
    required this.icon,
    required this.title,
    this.subtitle,
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
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium,
                )
              : null,
        ),
      ),
    );
  }
}
