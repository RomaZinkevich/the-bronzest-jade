import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:guess_who/models/character_set_draft.dart";
import "package:guess_who/widgets/character_grid.dart";
import "package:guess_who/widgets/draft_header.dart";
import "package:guess_who/widgets/retro_button.dart";

class DraftSection extends StatelessWidget {
  final CharacterSetDraft draft;
  final bool isExpanded;
  final bool isAddingCharacter;
  final bool isSubmitting;
  final Character? editingCharacter;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  final Function(Character character, bool shouldUpload) onSaveCharacter;
  final Function(Character character) onEditCharacter;
  final Function(Character character) onDeleteCharacter;
  final VoidCallback onAddNew;
  final VoidCallback onCancelAdd;
  final VoidCallback onSubmit;
  final VoidCallback onUploadAll;

  const DraftSection({
    super.key,
    required this.draft,
    required this.isExpanded,
    required this.isAddingCharacter,
    required this.isSubmitting,
    required this.onToggle,
    required this.onDelete,
    required this.onToggleVisibility,
    required this.onSaveCharacter,
    required this.onAddNew,
    required this.onCancelAdd,
    required this.onSubmit,
    required this.onUploadAll,
    required this.onEditCharacter,
    required this.onDeleteCharacter,
    this.editingCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: draft.isPublic ? theme.primary : theme.error,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black26),
        ],
      ),
      child: Column(
        children: [
          DraftHeader(
            draft: draft,
            isExpanded: isExpanded,
            onToggle: onToggle,
            onDelete: onDelete,
            onToggleVisibility: onToggleVisibility,
          ),

          SizedBox(
            width: double.infinity,
            child: ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: ClipRect(
                          child: Column(
                            children: [
                              CharacterGrid(
                                characters: draft.characters,
                                isAddingCharacter: isAddingCharacter,
                                editingCharacter: editingCharacter,
                                isComplete: draft.isComplete,
                                onSaveCharacter: onSaveCharacter,
                                onAddNew: onAddNew,
                                onCancelAdd: onCancelAdd,
                                onEditCharacter: onEditCharacter,
                                onDeleteCharacter: onDeleteCharacter,
                              ),

                              if (draft.isComplete && !isAddingCharacter) ...[
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    children: [
                                      RetroButton(
                                        text: "UPLOAD ALL IMAGES",
                                        fontSize: 16,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 32,
                                        ),
                                        backgroundColor: theme.secondary,
                                        foregroundColor: theme.tertiary,
                                        icon: Icons.cloud_upload_rounded,
                                        iconSize: 24,
                                        iconAtEnd: true,
                                        onPressed: onUploadAll,
                                      ),
                                      const SizedBox(height: 8),
                                      RetroButton(
                                        text: isSubmitting
                                            ? "SUBMITTING..."
                                            : "SUBMIT SET",
                                        fontSize: 18,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 32,
                                        ),
                                        backgroundColor: theme.error,
                                        foregroundColor: theme.tertiary,
                                        icon: isSubmitting
                                            ? Icons.hourglass_empty
                                            : Icons.send_rounded,
                                        iconSize: 26,
                                        iconAtEnd: true,
                                        onPressed: isSubmitting
                                            ? () {}
                                            : onSubmit,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
