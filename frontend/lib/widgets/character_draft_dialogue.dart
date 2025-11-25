import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:guess_who/widgets/animated_labeled_input.dart';
import 'package:guess_who/widgets/inner_shadow_input.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';
import 'package:http/http.dart';

class CharacterDraftDialogue extends StatefulWidget {
  final Function(String name, bool isPublic) onCreateDraft;

  const CharacterDraftDialogue({required this.onCreateDraft});

  @override
  State<CharacterDraftDialogue> createState() => _CharacterDraftDialogueState();
}

class _CharacterDraftDialogueState extends State<CharacterDraftDialogue> {
  final TextEditingController _nameController = TextEditingController();
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
      ),
      title: Text(
        "New Character Set",
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          AnimatedLabeledInput(
            controller: _nameController,
            label: "Draft Name",
            hint: "Name your draft...",
          ),

          InkWell(
            onTap: () {
              setState(() {
                _isPublic = !_isPublic;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Set visibility",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _isPublic
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.error,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 22,
                      color: _isPublic
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          RetroButton(
            text: "Submit",
            onPressed: () {
              widget.onCreateDraft(_nameController.text, _isPublic);
            },

            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),

            icon: Icons.upload_rounded,
            iconSize: 30,
            iconAtEnd: false,
            iconSpacing: 0,
          ),
        ],
      ),
    );
  }
}
