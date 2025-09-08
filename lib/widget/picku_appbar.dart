import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class PickUAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PickUAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.showBackButton = true,
    this.actions,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: showBackButton
          ? IconButton(
        onPressed: onBackPressed ?? () => Get.back(),
        icon: const Icon(LineAwesomeIcons.angle_left_solid),
      )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}