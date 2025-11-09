import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';

Future<void> makeGuessDialogue(
  BuildContext context, {
  required List<Character> availableCharacters,
  required void Function(Character character) onGuessSelected,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        title: Text(
          "Make Your Guess",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: availableCharacters.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "No characters available! Flip some back to make a guess.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCharacters.length,
                  itemBuilder: (context, index) {
                    final character = availableCharacters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            character.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Theme.of(context).colorScheme.secondary,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          character.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onGuessSelected(character);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
