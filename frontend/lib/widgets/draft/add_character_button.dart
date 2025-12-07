import "package:flutter/material.dart";
import "package:guess_who/services/audio_manager.dart";

class AddCharacterButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddCharacterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        AudioManager().playPopupSfx();
        onTap.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.primary.withAlpha(150),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.secondary, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: theme.tertiary, size: 48),
            const SizedBox(height: 4),
            Text(
              "ADD NEW",
              style: TextStyle(
                color: theme.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
