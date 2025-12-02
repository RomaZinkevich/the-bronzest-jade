import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";

class CharacterGridItem extends StatelessWidget {
  final Character character;
  final VoidCallback? onTap;

  const CharacterGridItem({super.key, required this.character, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.secondary, width: 2),
          color: theme.secondary,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: character.imageFile != null
                    ? Image.file(
                        character.imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: theme.primary.withAlpha(100),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.secondary,
                        ),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              color: theme.secondary,
              child: Text(
                character.name,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
