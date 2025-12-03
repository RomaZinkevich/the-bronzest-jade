import 'package:flutter/material.dart';
import 'package:guess_who/widgets/common/retro_button.dart';

class CharacterDraftDialogue extends StatefulWidget {
  final Function(String name, bool isPublic) onCreateDraft;

  const CharacterDraftDialogue({super.key, required this.onCreateDraft});

  @override
  State<CharacterDraftDialogue> createState() => _CharacterDraftDialogueState();
}

class _CharacterDraftDialogueState extends State<CharacterDraftDialogue> {
  final TextEditingController _nameController = TextEditingController();
  bool _isPublic = true;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: theme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.tertiary, width: 4),
      ),
      title: Text(
        "Define New Set",
        style: TextStyle(
          color: theme.tertiary,
          shadows: [
            Shadow(
              blurRadius: 4,
              offset: const Offset(0, 2),
              color: theme.shadow,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          TextField(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,

              hintText: "Name your draft...",
              labelText: "Draft Name",
              errorText: _errorText,

              errorStyle: TextStyle(
                color: theme.tertiary,
                backgroundColor: theme.error,

                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    color: theme.shadow,
                    blurRadius: 8,
                  ),
                ],
              ),
              labelStyle: TextStyle(
                color: theme.tertiary,
                fontWeight: FontWeight.bold,
              ),
              hintStyle: TextStyle(
                color: theme.tertiary.withAlpha(140),
                fontWeight: FontWeight.bold,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(width: 2, color: theme.tertiary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(width: 2, color: theme.tertiary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(width: 2, color: theme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(width: 2, color: theme.error),
              ),
            ),
            controller: _nameController,
            style: TextStyle(color: theme.tertiary),
          ),

          const SizedBox(height: 12),

          InkWell(
            onTap: () {
              setState(() {
                _isPublic = !_isPublic;
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(width: 2, color: theme.tertiary),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "set visibility",
                    style: TextStyle(color: theme.tertiary, fontSize: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isPublic ? theme.primary : theme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 22,
                      color: _isPublic ? theme.tertiary : theme.tertiary,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          color: theme.shadow,
                          blurRadius: 8,
                        ),
                      ],
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
              if (_nameController.text.trim().isEmpty) {
                setState(() {
                  _errorText = "  Name is required‎ ‎ ";
                });

                return;
              }
              widget.onCreateDraft(_nameController.text, _isPublic);
            },

            fontSize: 18,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }
}
