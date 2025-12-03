import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:guess_who/widgets/add_character_button.dart";
import "package:guess_who/widgets/character_grid_item.dart";
import "package:guess_who/widgets/character_input_form.dart";

class CharacterGrid extends StatelessWidget {
  final List<Character> characters;
  final bool isAddingCharacter;
  final Character? editingCharacter;
  final bool isComplete;
  final Function(Character character, bool shouldUpload) onSaveCharacter;
  final VoidCallback onAddNew;
  final VoidCallback onCancelAdd;
  final Function(Character character) onEditCharacter;
  final Function(Character character) onDeleteCharacter;

  const CharacterGrid({
    super.key,
    required this.characters,
    required this.isAddingCharacter,
    required this.isComplete,
    required this.onSaveCharacter,
    required this.onAddNew,
    required this.onCancelAdd,
    required this.onEditCharacter,
    required this.onDeleteCharacter,
    this.editingCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = editingCharacter != null;

    int itemCount = characters.length;
    if ((isAddingCharacter || isEditing) && !isComplete) itemCount++;
    if (!isComplete && !isAddingCharacter && !isEditing) itemCount++;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < characters.length) {
          final character = characters[index];

          if (isEditing && character.id == editingCharacter!.id) {
            return CharacterInputForm(
              character: editingCharacter,
              onSave: onSaveCharacter,
              onCancel: onCancelAdd,
            );
          }

          return CharacterGridItem(
            character: character,
            onTap: () => onEditCharacter(character),
            onEdit: () => onEditCharacter(character),
            onDelete: () => onDeleteCharacter(character),
          );
        } else if (isAddingCharacter) {
          return CharacterInputForm(
            onSave: onSaveCharacter,
            onCancel: onCancelAdd,
          );
        } else if (!isComplete) {
          return AddCharacterButton(onTap: onAddNew);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
