import "package:flutter/material.dart";
import "package:guess_who/models/character_set_draft.dart";

class DraftHeader extends StatelessWidget {
  final CharacterSetDraft draft;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const DraftHeader({
    super.key,
    required this.draft,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final progress = draft.characterCount / 16;

    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                Icons.expand_circle_down_rounded,
                color: isExpanded
                    ? theme.tertiary
                    : theme.tertiary.withAlpha(200),
                size: 32,
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.tertiary.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                draft.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                color: draft.isPublic ? theme.primary : theme.error,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.name,
                    style: TextStyle(color: theme.tertiary, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        draft.isComplete
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_empty_rounded,
                        size: 14,
                        color: theme.tertiary.withAlpha(200),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "${draft.characterCount} / 16",
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.tertiary.withAlpha(200),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: theme.tertiary.withAlpha(100),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.tertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              color: theme.tertiary,
              icon: Icon(Icons.more_vert, color: theme.tertiary),
              onSelected: (value) {
                if (value == "delete") {
                  onDelete();
                } else if (value == "visibility") {
                  onToggleVisibility();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "visibility",
                  child: Row(
                    children: [
                      Icon(
                        draft.isPublic
                            ? Icons.lock_rounded
                            : Icons.public_rounded,
                        size: 20,
                        color: theme.secondary,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        draft.isPublic ? "Make Private" : "Make Public",
                        style: TextStyle(color: theme.secondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: theme.error),

                      const SizedBox(width: 8),

                      Text(
                        "Delete Draft",
                        style: TextStyle(color: theme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
