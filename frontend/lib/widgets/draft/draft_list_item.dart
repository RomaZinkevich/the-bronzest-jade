import 'package:flutter/material.dart';
import 'package:guess_who/models/character_set_draft.dart';

class DraftListItem extends StatelessWidget {
  final CharacterSetDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onToggleVisibility;

  const DraftListItem({
    super.key,
    required this.draft,
    required this.onTap,
    required this.onDelete,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final progress = draft.characterCount / 16;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: draft.isComplete ? Colors.green : theme.primary,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: draft.isPublic ? theme.secondary : theme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    draft.isPublic ? Icons.public : Icons.lock,
                    color: theme.tertiary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    draft.name.isEmpty ? "Unnamed" : draft.name,
                    style: TextStyle(fontSize: 18, color: theme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.primary),
                  color: theme.tertiary,
                  onSelected: (value) {
                    if (value == "delete") {
                      onDelete();
                    } else if (value == "visibility") {
                      onToggleVisibility?.call();
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
                            color: theme.secondary,
                            size: 20,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            draft.isPublic ? "Make private" : "Make public",
                            style: TextStyle(color: theme.secondary),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: theme.error,
                          ),

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

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  draft.isComplete
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_empty_rounded,
                  size: 16,
                  color: draft.isComplete ? Colors.green : theme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  "${draft.characterCount} / 16 characters",
                  style: TextStyle(fontSize: 14, color: theme.secondary),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.primary.withAlpha(100),
                valueColor: AlwaysStoppedAnimation<Color>(
                  draft.isComplete ? Colors.green : theme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
