import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isFlipped;
  final bool isSelectionMode;
  final VoidCallback? onFlip;
  final VoidCallback? onSelect;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isFlipped,
    required this.isSelectionMode,
    this.onFlip,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          onSelect?.call();
        } else {
          onFlip?.call();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isFlipped ? colorScheme.secondary : colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.secondary, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedOpacity(
          opacity: isSelectionMode
              ? (isFlipped ? 1.0 : 0.3)
              : (isFlipped ? 0.3 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //* CHARACTER IMAGE
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      character.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(error.toString());
                        return Container(
                          color: colorScheme.secondary.withAlpha(100),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.secondary.withAlpha(100),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.tertiary,
                              ),
                              strokeCap: StrokeCap.round,
                              strokeWidth: 5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              //* CHARACTER NAME
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  character.name,
                  style: TextStyle(fontSize: 12, color: colorScheme.tertiary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
