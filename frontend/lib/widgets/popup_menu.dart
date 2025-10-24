import 'package:flutter/material.dart';
import 'package:guess_who/widgets/retro_button.dart';

class PopupMenu extends StatelessWidget {
  final String title;
  final List<RetroPopupMenuItem>? items;
  final VoidCallback? onClose;
  final Widget? customContent;
  final double? maxHeight;
  final bool showCloseButton;

  const PopupMenu({
    super.key,
    required this.title,
    this.items,
    this.customContent,
    this.maxHeight,
    this.onClose,
    this.showCloseButton = true,
  }) : assert(
         items != null || customContent != null,
         "Either items or customContent must be provided",
       );

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    List<RetroPopupMenuItem>? items,
    Widget? customContent,
    double? maxHeight,
    bool showCloseButton = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopupMenu(
          title: title,
          items: items,
          customContent: customContent,
          maxHeight: maxHeight,
          showCloseButton: showCloseButton,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),

      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
        ),
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

            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child:
                    customContent ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items!
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: item,
                            ),
                          )
                          .toList(),
                    ),
              ),
            ),

            if (showCloseButton) ...[
              const SizedBox(height: 20),

              RetroButton(
                text: "Close",
                fontSize: 18,

                icon: Icons.exit_to_app_rounded,
                iconAtEnd: true,
                iconSize: 20,
                iconSpacing: 10,

                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                borderRadius: 10,
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.tertiary,
                onPressed: () {
                  Navigator.of(context).pop();
                  onClose?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RetroPopupMenuItem extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const RetroPopupMenuItem({
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

class RoomListItem extends StatelessWidget {
  final String roomName;
  final String roomCode;
  final int playerCount;
  final int maxPlayers;
  final bool isPrivate;
  final VoidCallback onJoin;

  const RoomListItem({
    super.key,
    required this.roomName,
    required this.roomCode,
    required this.playerCount,
    required this.maxPlayers,
    required this.onJoin,
    this.isPrivate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = playerCount >= maxPlayers;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isPrivate ? 5 : 3),
                decoration: BoxDecoration(
                  color: isPrivate
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  isPrivate ? Icons.lock : Icons.public,
                  color: isPrivate
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.tertiary,
                  size: isPrivate ? 20 : 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  roomName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          //* ROOM CODE
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.vpn_key,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),

              const SizedBox(width: 6),

              Text(
                roomCode,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),

          //* PLAYER COUNT
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),

              const SizedBox(width: 6),

              Text(
                "$playerCount/$maxPlayers",
                style: TextStyle(
                  fontSize: 14,
                  color: isFull
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          RetroButton(
            text: isFull ? "FULL" : "JOIN",
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            borderRadius: 8,
            backgroundColor: isFull
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.tertiary,
            borderColor: Theme.of(context).colorScheme.tertiary,
            borderWidth: 3,
            onPressed: isFull
                ? () {}
                : () {
                    Navigator.of(context).pop();
                    onJoin();
                  },
          ),
        ],
      ),
    );
  }
}
