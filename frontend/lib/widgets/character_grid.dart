import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:guess_who/widgets/add_character_button.dart";
import "package:guess_who/widgets/character_grid_item.dart";
import "package:guess_who/widgets/character_input_form.dart";

class CharacterGrid extends StatelessWidget {
  final List<Character> characters;
  final bool isAddingCharacter;
  final bool isComplete;
  final Function(Character character, bool shouldUpload) onSaveCharacter;
  final VoidCallback onAddNew;
  final VoidCallback onCancelAdd;

  const CharacterGrid({
    super.key,
    required this.characters,
    required this.isAddingCharacter,
    required this.isComplete,
    required this.onSaveCharacter,
    required this.onAddNew,
    required this.onCancelAdd,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = isComplete
        ? characters.length
        : characters.length + (isAddingCharacter ? 2 : 1);

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
          return CharacterGridItem(character: characters[index], onTap: () {});
        } else if (isAddingCharacter && index == characters.length) {
          return CharacterInputForm(
            onSave: onSaveCharacter,
            onCancel: onCancelAdd,
          );
        }

        if (!isComplete) {
          return AddCharacterButton(onTap: onAddNew);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
