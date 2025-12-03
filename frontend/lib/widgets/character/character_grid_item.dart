import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";

class CharacterGridItem extends StatelessWidget {
  final Character character;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CharacterGridItem({
    super.key,
    required this.character,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final isUploaded =
        character.uploadedFilename != null &&
        character.uploadedFilename!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUploaded ? Colors.green : theme.tertiary,
            width: isUploaded ? 3 : 2,
          ),
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
                        width: double.infinity,
                        color: theme.primary.withAlpha(100),
                        child: Icon(
                          Icons.person_search_rounded,
                          size: 60,
                          color: theme.tertiary,
                        ),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              color: isUploaded ? Colors.green : theme.tertiary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PopupMenuButton<String>(
                    color: theme.tertiary,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert,
                      size: 26,
                      color: theme.secondary,
                    ),
                    onSelected: (value) {
                      if (value == "edit" && onEdit != null) {
                        onEdit!();
                      } else if (value == "delete" && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: theme.secondary),

                            const SizedBox(width: 8),

                            Text(
                              "Edit",
                              style: TextStyle(color: theme.secondary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: theme.error),
                            const SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: TextStyle(color: theme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Text(
                      character.name,
                      style: TextStyle(fontSize: 20, color: theme.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            if (isUploaded)
              Positioned(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_done,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
