import 'package:flutter/material.dart';

class RetroIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final IconData? icon;
  final String? imagePath;
  final double size;
  final double iconSize;
  final double borderWidth;

  const RetroIconButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.icon,
    this.imagePath,
    this.size = 80,
    this.iconSize = 40,
    this.borderWidth = 4,
  }) : assert(
         icon != null || imagePath != null,
         'Either icon or imagePath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final iColor = iconColor ?? Theme.of(context).colorScheme.tertiary;

    Widget content;
    if (imagePath != null) {
      content = Image.asset(
        imagePath!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.cover,
      );
    } else {
      content = Icon(icon, size: iconSize, color: iColor);
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: iconColor,
        padding: EdgeInsets.all(8),
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}
