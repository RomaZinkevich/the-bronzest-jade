import 'package:flutter/material.dart';

class RetroIconButton extends StatelessWidget {
  final String? tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final IconData? icon;
  final String? imagePath;
  final EdgeInsets? margin;
  final double padding;
  final double iconSize;
  final double borderWidth;

  const RetroIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = "Button",
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.icon,
    this.imagePath,
    this.margin = const EdgeInsets.all(0),
    this.padding = 8,
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

    return Tooltip(
      message: tooltip,
      margin: EdgeInsets.only(top: 10),
      child: Container(
        margin: margin,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(
              side: BorderSide(
                width: borderWidth,
                color: borderColor ?? Theme.of(context).colorScheme.tertiary,
              ),
            ),
            backgroundColor: bgColor,
            foregroundColor: iconColor,
            padding: EdgeInsets.all(padding),
            elevation: 2,
          ),
          onPressed: onPressed,
          child: content,
        ),
      ),
    );
  }
}
