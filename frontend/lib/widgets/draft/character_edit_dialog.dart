import "dart:io";

import "package:flutter/material.dart";
import "package:guess_who/models/character.dart";
import "package:guess_who/services/api_service.dart";
import "package:image_picker/image_picker.dart";

class CharacterEditDialog extends StatefulWidget {
  final Character character;
  final Function(Character updatedCharacter) onSave;
  final Function(String? filenameToDelete) onDelete;

  const CharacterEditDialog({
    super.key,
    required this.character,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<CharacterEditDialog> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _imageChanged = false;
  bool _isUploading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.character.name;
    _selectedImage = widget.character.imageFile;
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
        _imageChanged = true;
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

  Future<void> _saveChanges({required bool shouldUpload}) async {
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

    String? newFilename;
    String newImageUrl = widget.character.imageUrl;

    if (shouldUpload && _imageChanged && _selectedImage != null) {
      setState(() => _isUploading = true);

      try {
        newFilename = await ApiService.uploadImage(_selectedImage!);
        newImageUrl = "https://guesswho.190304.xyz/api/images/$newFilename";

        if (widget.character.uploadedFilename != null &&
            widget.character.uploadedFilename!.isNotEmpty) {
          try {
            await ApiService.deleteImage(widget.character.uploadedFilename!);
          } catch (e) {
            debugPrint("Failed to delete old image: $e");
          }
        }

        setState(() => _isUploading = false);
      } catch (e) {
        setState(() => _isUploading = false);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload image: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    final updatedCharacter = widget.character.copyWith(
      name: name,
      imageFile: _selectedImage,
      uploadedFilename: _imageChanged && shouldUpload
          ? newFilename
          : (_imageChanged ? null : widget.character.uploadedFilename),
      imageUrl: _imageChanged && shouldUpload
          ? newImageUrl
          : (_imageChanged ? "" : widget.character.imageUrl),
    );

    widget.onSave(updatedCharacter);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteCharacter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Character?",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          "Are you sure you want to delete \"${widget.character.name}\"?",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    widget.onDelete(widget.character.uploadedFilename);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final isUploaded =
        widget.character.uploadedFilename != null &&
        widget.character.uploadedFilename!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.tertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primary, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Edit Character",
              style: TextStyle(
                fontSize: 24,
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.secondary, width: 2),
                ),
                child: Stack(
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 64,
                          color: theme.secondary,
                        ),
                      ),

                    if (isUploaded && !_imageChanged)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_done,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                    if (_imageChanged)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "TAP TO CHANGE",
                          style: TextStyle(
                            color: theme.tertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: theme.primary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Character name...",
                hintStyle: TextStyle(
                  color: theme.primary.withAlpha(140),
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: theme.secondary.withAlpha(50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.secondary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.secondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primary, width: 3),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_isUploading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.secondary),
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveChanges(shouldUpload: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.secondary,
                            foregroundColor: theme.tertiary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.save, size: 20),
                          label: const Text(
                            "SAVE",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_imageChanged) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _saveChanges(shouldUpload: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: theme.tertiary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_upload, size: 20),
                            label: const Text(
                              "SAVE & UPLOAD",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _deleteCharacter,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.error,
                            side: BorderSide(color: theme.error, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Icon(
                            _isDeleting ? Icons.hourglass_empty : Icons.delete,
                            size: 20,
                          ),
                          label: Text(
                            _isDeleting ? "DELETING..." : "DELETE",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: theme.secondary, fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
