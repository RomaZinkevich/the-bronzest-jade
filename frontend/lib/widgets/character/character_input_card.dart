import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CharacterInputCard extends StatefulWidget {
  final Character? character;
  final Function(Character character) onSave;
  final VoidCallback? onCancel;

  const CharacterInputCard({
    super.key,
    this.character,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<StatefulWidget> createState() => _CharacterInputCardState();
}

class _CharacterInputCardState extends State<CharacterInputCard> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _uploadedFilename;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    if (widget.character != null) {
      _nameController.text = widget.character!.name;
      _uploadedFilename = widget.character!.uploadedFilename;
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
        _isUploading = true;
      });

      final filename = await ApiService.uploadImage(_selectedImage!);

      setState(() {
        _uploadedFilename = filename;
        _isUploading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Image uploaded successfully",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to upload image $e",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _saveCharacter() {
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

    if (_uploadedFilename == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please upload an image",
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
      imageUrl: "${ApiService.baseUrl}/images/$_uploadedFilename",
      uploadedFilename: _uploadedFilename,
    );

    widget.onSave(character);
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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.secondary, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.secondary, width: 2),
              ),
              child: _isUploading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.tertiary,
                            ),
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Uploading...",
                            style: TextStyle(
                              color: theme.tertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 64,
                          color: theme.tertiary.withAlpha(200),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "TAP TO UPLOAD IMAGE",
                          style: TextStyle(
                            color: theme.tertiary.withAlpha(200),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,

              hintText: "Name your character...",
              labelText: "Character Name",

              labelStyle: TextStyle(
                color: theme.tertiary.withAlpha(140),
                fontWeight: FontWeight.bold,
              ),
              hintStyle: TextStyle(
                color: theme.tertiary.withAlpha(140),
                fontWeight: FontWeight.bold,
              ),

              border: InputBorder.none,

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),

              filled: true,
              fillColor: theme.secondary,
            ),
            controller: _nameController,
            style: TextStyle(color: theme.tertiary),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (widget.onCancel != null) ...[
                RetroIconButton(
                  backgroundColor: theme.error,
                  icon: Icons.close_rounded,
                  iconSize: 40,
                  onPressed: widget.onCancel!,

                  tooltip: "Cancel character creation",
                ),
              ],

              RetroIconButton(
                backgroundColor: theme.secondary,
                icon: Icons.upload_rounded,
                iconSize: 40,
                onPressed: _saveCharacter,
                tooltip: "Upload character creation",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
