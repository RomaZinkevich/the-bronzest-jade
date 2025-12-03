import "dart:io";

import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:image_picker/image_picker.dart";
import "package:path_provider/path_provider.dart";
import "package:uuid/uuid.dart";
import "package:path/path.dart" as path;

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

  @override
  void initState() {
    super.initState();

    if (widget.character != null) {
      _nameController.text = widget.character!.name;
      _selectedImage = widget.character!.imageFile;
    }
  }

  Future<File> _copyToAppDirectory(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory("${directory.path}/character_images");

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = "${const Uuid().v4()}${path.extension(sourceFile.path)}";
    final targetPath = "${imagesDir.path}/$fileName";

    return await sourceFile.copy(targetPath);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint("Something went wrong when picking image");
        return;
      }

      final tempFile = File(pickedFile.path);
      final permanentFile = await _copyToAppDirectory(tempFile);

      setState(() {
        _selectedImage = permanentFile;
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

  Future<void> _confirmAndUpload() async {
    final theme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.tertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.primary, width: 3),
        ),
        title: Text(
          "Upload Image?",
          style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This will:",
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              "Upload image to server",
              Icons.circle,
              theme.primary,
            ),
            _buildBulletPoint(
              "Save character with upload",
              Icons.circle,
              theme.secondary,
            ),
            if (widget.character?.uploadedFilename != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.error.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.error, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: theme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Old image will be replaced",
                        style: TextStyle(color: theme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: theme.secondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: theme.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: const Text("Upload"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _saveCharacter(shouldUpload: true);
    }
  }

  Widget _buildBulletPoint(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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

    final bool imageChanged =
        widget.character != null &&
        _selectedImage != widget.character!.imageFile;

    final character = Character(
      id: widget.character?.id ?? const Uuid().v4(),
      name: name,
      imageUrl: (imageChanged && !shouldUpload)
          ? ""
          : (widget.character?.imageUrl ?? ""),
      imageFile: _selectedImage,
      uploadedFilename: (imageChanged && !shouldUpload)
          ? null
          : widget.character?.uploadedFilename,
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
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

                    if (_selectedImage != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmAndUpload(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.tertiary,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(100),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                color: theme.tertiary,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (widget.character?.uploadedFilename != null &&
                        widget.character?.uploadedFilename!.isNotEmpty == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.tertiary, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                color: theme.tertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "UPLOADED",
                                style: TextStyle(
                                  color: theme.tertiary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                color: theme.secondary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Name...",
                hintStyle: TextStyle(
                  color: theme.primary.withAlpha(140),
                  fontWeight: FontWeight.bold,
                ),
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
