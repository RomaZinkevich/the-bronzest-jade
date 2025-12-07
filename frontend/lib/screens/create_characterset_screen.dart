import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/character_set_draft.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/audio_manager.dart';
import 'package:guess_who/services/draft_storage_service.dart';
import 'package:guess_who/widgets/common/retro_button.dart';
import 'package:guess_who/widgets/common/retro_icon_button.dart';
import 'package:guess_who/widgets/draft/character_draft_dialogue.dart';
import 'package:guess_who/widgets/draft/draft_section.dart';
import 'package:uuid/uuid.dart';
import 'package:guess_who/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class CreateCharactersetScreen extends StatefulWidget {
  final String playerId;

  const CreateCharactersetScreen({super.key, required this.playerId});

  @override
  State<CreateCharactersetScreen> createState() =>
      _CreateCharactersetScreenState();
}

class _CreateCharactersetScreenState extends State<CreateCharactersetScreen> {
  List<CharacterSetDraft> _drafts = [];
  final Map<String, bool> _isAddingCharacter = {};
  final Map<String, Character?> _editingCharacter = {};
  String? _expandedDraftId;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);

    try {
      final drafts = await DraftStorageService.loadDrafts();
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to load drafts: $e",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _createNewDraft() {
    AudioManager().playPopupSfx();

    showDialog(
      context: context,
      builder: (context) => CharacterDraftDialogue(
        onCreateDraft: (name, isPublic) {
          final draft = CharacterSetDraft(
            id: const Uuid().v4(),
            name: name,
            characters: [],
            isPublic: isPublic,
            lastModified: DateTime.now(),
          );

          setState(() {
            _drafts.insert(0, draft);
            _expandedDraftId = draft.id;
            _isAddingCharacter[draft.id] = true;
          });

          DraftStorageService.saveDraft(draft);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleDraft(String draftId) {
    setState(() {
      if (_expandedDraftId == draftId) {
        _expandedDraftId = null;
      } else {
        _expandedDraftId = draftId;
      }
    });
  }

  Future<void> _deleteDraft(CharacterSetDraft draft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        contentPadding: const EdgeInsets.all(30),
        titlePadding: const EdgeInsets.only(left: 30, top: 30, bottom: 0),
        title: Text(
          "Delete draft?",
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Text(
          "This will permanently delete \"${draft.name.isEmpty ? "Unnamed" : draft.name}\" and all its characters.",
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

          RetroButton(
            text: "Delete",
            onPressed: () {
              AudioManager().playAlertSfx();
              Navigator.pop(context, true);
            },
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DraftStorageService.deleteDraft(draft.id);

    setState(() {
      _drafts.removeWhere((d) => d.id == draft.id);
      if (_expandedDraftId == draft.id) {
        _expandedDraftId = null;
      }

      _isAddingCharacter.remove(draft.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Draft deleted", textAlign: TextAlign.center),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  Future<void> _toggleDraftVisibility(CharacterSetDraft draft) async {
    final updated = draft.copyWith(
      isPublic: !draft.isPublic,
      lastModified: DateTime.now(),
    );

    await DraftStorageService.saveDraft(updated);

    setState(() {
      final index = _drafts.indexWhere((d) => d.id == draft.id);
      if (index != -1) {
        _drafts[index] = updated;
      }
    });
  }

  void _saveCharacter(
    String draftId,
    Character character,
    bool shouldUpload,
  ) async {
    final draftIndex = _drafts.indexWhere((d) => d.id == draftId);
    if (draftIndex == -1) return;

    final draft = _drafts[draftIndex];
    final characters = List<Character>.from(draft.characters);

    Character finalCharacter = character;

    if (shouldUpload && character.imageFile != null) {
      try {
        setState(() {
          _isUploading = true;
        });

        final existingCharacter = characters
            .where((c) => c.id == character.id)
            .firstOrNull;

        final oldFilename = existingCharacter?.uploadedFilename;

        final filename = await ApiService.uploadImage(character.imageFile!);
        final imageUrl = "https://guesswho.190304.xyz/images/$filename";

        if (oldFilename != null &&
            oldFilename.isNotEmpty &&
            oldFilename != filename) {
          try {
            await ApiService.deleteImage(oldFilename);
          } catch (e) {
            debugPrint("Failed to delete old image: $e");
          }
        }

        finalCharacter = character.copyWith(
          uploadedFilename: filename,
          imageUrl: imageUrl,
        );

        setState(() {
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Image uploaded successfully",
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload image: $e"),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
    }

    final existingIndex = characters.indexWhere(
      (c) => c.id == finalCharacter.id,
    );
    if (existingIndex != -1) {
      characters[existingIndex] = finalCharacter;
    } else {
      characters.add(finalCharacter);
    }

    final updatedDraft = draft.copyWith(
      characters: characters,
      lastModified: DateTime.now(),
    );

    await DraftStorageService.saveDraft(updatedDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _drafts[draftIndex] = updatedDraft;
          _isAddingCharacter[draftId] = false;
          _editingCharacter[draftId] = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shouldUpload
                  ? "Character saved and uploaded"
                  : "Character saved locally",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _editCharacter(String draftId, Character character) {
    setState(() {
      _editingCharacter[draftId] = character;
      _isAddingCharacter[draftId] = false;
    });
  }

  void _showDeleteCharacterConfirmation(String draftId, Character character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.tertiary,
            width: 3,
          ),
        ),
        title: Text(
          "Delete Character?",
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to delete \"${character.name}\"?",
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 10),

            if (character.uploadedFilename != null &&
                character.uploadedFilename!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "This will also delete the uploaded image from the server.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCharacter(
                draftId,
                character.id,
                character.uploadedFilename,
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.tertiary,
              ),
            ),
            child: Text(
              "Delete",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCharacter(
    String draftId,
    String characterId,
    String? filenameToDelete,
  ) async {
    if (filenameToDelete != null && filenameToDelete.isNotEmpty) {
      try {
        await ApiService.deleteImage(filenameToDelete);
      } catch (e) {
        debugPrint("Failed to delete image from server: $e");
      }
    }

    final draftIndex = _drafts.indexWhere((d) => d.id == draftId);
    if (draftIndex == -1) return;

    final draft = _drafts[draftIndex];
    final characters = List<Character>.from(draft.characters);

    characters.removeWhere((c) => c.id == characterId);

    final updatedDraft = draft.copyWith(
      characters: characters,
      lastModified: DateTime.now(),
    );

    await DraftStorageService.saveDraft(updatedDraft);

    setState(() {
      _drafts[draftIndex] = updatedDraft;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Character deleted", textAlign: TextAlign.center),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _uploadAllImages(CharacterSetDraft draft) async {
    final unuploadedCount = draft.characters
        .where((c) => c.uploadedFilename == null || c.uploadedFilename!.isEmpty)
        .length;

    if (unuploadedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "All images already uploaded!",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final updatedCharacters = <Character>[];
      int uploadedCount = 0;

      for (final character in draft.characters) {
        if (character.imageFile != null &&
            (character.uploadedFilename == null ||
                character.uploadedFilename!.isEmpty)) {
          final filename = await ApiService.uploadImage(character.imageFile!);
          final imageUrl = "https://guesswho.190304.xyz/images/$filename";

          updatedCharacters.add(
            character.copyWith(uploadedFilename: filename, imageUrl: imageUrl),
          );
          uploadedCount++;
        } else {
          updatedCharacters.add(character);
        }
      }

      final updatedDraft = draft.copyWith(
        characters: updatedCharacters,
        lastModified: DateTime.now(),
      );

      await DraftStorageService.saveDraft(updatedDraft);

      setState(() {
        final index = _drafts.indexWhere((d) => d.id == draft.id);
        if (index != -1) {
          _drafts[index] = updatedDraft;
        }
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Uploaded $uploadedCount images successfully!",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload images: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitCharacterSet(CharacterSetDraft draft) async {
    final hasUnuploadedImages = draft.characters.any(
      (c) => c.uploadedFilename == null || c.uploadedFilename!.isEmpty,
    );

    if (hasUnuploadedImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please upload all images first",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      return;
    }

    if (!draft.isComplete) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final characterData = draft.characters
          .map((c) => {"name": c.name, "imageUrl": c.imageUrl})
          .toList();

      await ApiService.createCharacterSet(
        draft.name,
        draft.isPublic,
        characterData,
      );

      await DraftStorageService.deleteDraft(draft.id);

      setState(() {
        _drafts.removeWhere((d) => d.id == draft.id);
        _expandedDraftId = null;
        _isAddingCharacter.remove(draft.id);
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Character set created successfully",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create character set: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Create your set",
              style: TextStyle(
                fontSize: 20,
                color: theme.tertiary,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            toolbarHeight: 80,
            backgroundColor: theme.primary,
            foregroundColor: theme.tertiary,
            leading: Navigator.canPop(context)
                ? RetroIconButton(
                    icon: Icons.arrow_back_rounded,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    iconSize: 26,

                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 0,
                    ),
                    borderWidth: 2,

                    onPressed: () {
                      Navigator.of(context).pop();
                    },

                    tooltip: "Go back home",
                  )
                : null,
            actions: [
              RetroIconButton(
                onPressed: _createNewDraft,
                backgroundColor: theme.secondary,
                borderWidth: 2,
                borderColor: theme.tertiary,

                icon: Icons.add,
                iconSize: 30,
                iconColor: theme.tertiary,

                padding: 8,

                tooltip: "Create draft",
                playOnClick: false,
              ),
            ],
          ),
          body: Stack(
            children: [
              //* Background Image
              SizedBox.expand(
                child: Image(
                  image: AssetImage("assets/main_menu.png"),
                  fit: BoxFit.cover,
                  color: settings.isDarkMode
                      ? Colors.black.withOpacity(0.5)
                      : null,
                  colorBlendMode: settings.isDarkMode ? BlendMode.darken : null,
                ),
              ),

              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                  ),
                )
              else if (_drafts.isEmpty)
                Center(
                  child: InkWell(
                    onTap: _createNewDraft,
                    highlightColor: theme.tertiary,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                        color: theme.secondary.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.tertiary, width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            size: 80,
                            color: theme.tertiary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No drafts yet",
                            style: TextStyle(
                              color: theme.tertiary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            "Click here to add a new character set draft",
                            style: TextStyle(
                              color: theme.tertiary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._drafts.map((draft) {
                        final isExpanded = _expandedDraftId == draft.id;
                        final isAddingChar =
                            _isAddingCharacter[draft.id] ?? false;
                        final editingChar = _editingCharacter[draft.id];

                        return DraftSection(
                          draft: draft,
                          isExpanded: isExpanded,
                          isAddingCharacter: isAddingChar,
                          editingCharacter: editingChar,
                          isSubmitting: _isSubmitting,
                          onToggle: () => _toggleDraft(draft.id),
                          onDelete: () => _deleteDraft(draft),
                          onToggleVisibility: () =>
                              _toggleDraftVisibility(draft),
                          onSaveCharacter: (character, shouldUpload) =>
                              _saveCharacter(draft.id, character, shouldUpload),
                          onEditCharacter: (character) {
                            if (editingChar != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Finish editing character first",
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: theme.error,
                                  ),
                                );
                              }

                              return;
                            }
                            _editCharacter(draft.id, character);
                          },
                          onDeleteCharacter: (character) =>
                              _showDeleteCharacterConfirmation(
                                draft.id,
                                character,
                              ),
                          onAddNew: () => setState(() {
                            if (_isAddingCharacter[draft.id] == true ||
                                editingChar != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Finish adding or editing your character",
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: theme.error,
                                  ),
                                );
                              }

                              return;
                            }
                            _isAddingCharacter[draft.id] = true;
                            _editingCharacter[draft.id] = null;
                          }),
                          onCancelAdd: () => setState(() {
                            _isAddingCharacter[draft.id] = false;
                            _editingCharacter[draft.id] = null;
                          }),
                          onUploadAll: () => _uploadAllImages(draft),
                          onSubmit: () => _submitCharacterSet(draft),
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),

              if (_isUploading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.tertiary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primary, width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.secondary,
                            ),
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Uploading images...",
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
