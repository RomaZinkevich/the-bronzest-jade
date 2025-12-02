import "dart:io";

import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:image_picker/image_picker.dart";
import "package:uuid/uuid.dart";

class CharacterInputForm extends StatefulWidget {
  final Character? character;
  final Function(Character character, bool shouldUpload) onSave;
  final VoidCallback? onCancel;

  const CharacterInputForm({
    super.key,
    this.character,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<CharacterInputForm> createState() => _CharacterInputFormState();
}

class _CharacterInputFormState extends State<CharacterInputForm> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();

    if (widget.character != null) {
      _nameController.text = widget.character!.name;
      _selectedImage = widget.character!.imageFile;
      _hasImage = widget.character!.imageFile != null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _hasImage = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _saveCharacter({required bool shouldUpload}) {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter a character name",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please select an image",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final character = Character(
      id: widget.character?.id ?? const Uuid().v4(),
      name: name,
      imageUrl: widget.character?.imageUrl ?? "",
      imageFile: _selectedImage,
      uploadedFilename: widget.character?.uploadedFilename,
    );

    widget.onSave(character, shouldUpload);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.tertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary, width: 3),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.secondary, width: 2),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 48,
                            color: theme.secondary,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "TAP TO\nSELECT",
                            style: TextStyle(
                              color: theme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Name...",
                hintStyle: TextStyle(
                  color: theme.primary.withAlpha(140),
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: theme.secondary.withAlpha(50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.secondary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.secondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: theme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (widget.onCancel != null) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.error,
                        foregroundColor: theme.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Icon(Icons.close, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveCharacter(shouldUpload: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Icon(Icons.check, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
