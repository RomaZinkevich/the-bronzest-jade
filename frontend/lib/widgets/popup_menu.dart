import 'package:flutter/material.dart';

class PopupMenu extends StatelessWidget {
  final String title;
  final List<PopupMenuItem> items;
  final VoidCallback? onClose;

  const PopupMenu({
    super.key,
    required this.title,
    required this.items,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<PopupMenuItem> items,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopupMenu(title: title, items: items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Container(height: 3, color: Theme.of(context).colorScheme.primary),

            const SizedBox(height: 20),

            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: item,
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: Text(
                "Close",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PopupMenuItem extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const PopupMenuItem({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final txtColor = textColor ?? Theme.of(context).colorScheme.tertiary;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: txtColor, size: 28),
              const SizedBox(width: 12),
            ],

            if (imagePath != null) ...[
              Image.asset(imagePath!, width: 28, height: 28),
              const SizedBox(width: 12),
            ],

            Text(text, style: TextStyle(fontSize: 18, color: txtColor)),
          ],
        ),
      ),
    );
  }
}
