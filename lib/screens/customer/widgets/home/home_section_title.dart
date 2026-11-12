import 'package:flutter/material.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText!)),
      ],
    );
  }
}
