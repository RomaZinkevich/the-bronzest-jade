import 'package:flutter/material.dart';
import 'package:guess_who/services/audio_manager.dart';

class RetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final IconData? icon;
  final bool iconAtEnd;
  final double iconSpacing;
  final double fontSize;
  final double iconSize;
  final EdgeInsets? padding;
  final double borderRadius;
  final double borderWidth;
  final bool playOnClick;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.icon,
    this.iconAtEnd = true,
    this.fontSize = 16,
    this.iconSize = 42,
    this.iconSpacing = 12,
    this.padding,
    this.borderRadius = 100,
    this.borderWidth = 4,
    this.playOnClick = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.symmetric(horizontal: 50, vertical: 15);

    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.error;
    final fgColor = foregroundColor ?? Theme.of(context).colorScheme.tertiary;
    final bColor = borderColor ?? Theme.of(context).colorScheme.tertiary;

    Widget content;

    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: iconAtEnd
            ? [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                SizedBox(width: iconSpacing),
                Icon(icon, size: iconSize, color: fgColor),
              ]
            : [
                Icon(icon, size: iconSize, color: fgColor),
                SizedBox(width: iconSpacing),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ],
      );
    } else {
      content = Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: bColor, width: borderWidth),
        ),
        padding: padding ?? defaultPadding,
      ),
      onPressed: () {
        playOnClick ? AudioManager().playButtonClickVariation() : null;
        onPressed.call();
      },
      child: content,
    );
  }
}
