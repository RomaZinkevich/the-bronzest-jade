import 'package:flutter/material.dart';
import 'package:guess_who/models/character.dart';
import 'package:guess_who/models/character_set_draft.dart';
import 'package:guess_who/services/api_service.dart';
import 'package:guess_who/services/draft_storage_service.dart';
import 'package:guess_who/widgets/character_draft_dialogue.dart';
import 'package:guess_who/widgets/character_input_card.dart';
import 'package:guess_who/widgets/draft_list_item.dart';
import 'package:guess_who/widgets/retro_button.dart';
import 'package:guess_who/widgets/retro_icon_button.dart';
import 'package:uuid/uuid.dart';

class CreateCharactersetScreen extends StatefulWidget {
  final String playerId;

  const CreateCharactersetScreen({super.key, required this.playerId});

  @override
  State<CreateCharactersetScreen> createState() =>
      _CreateCharactersetScreenState();
}

class _CreateCharactersetScreenState extends State<CreateCharactersetScreen> {
  List<CharacterSetDraft> _drafts = [];
  Map<String, bool> _isAddingCharacter = {};

  String? _expandedDraftId;

  bool _isLoading = false;
  bool _isSubmitting = false;

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

  void _saveCharacter(String draftId, Character character) {
    final draftIndex = _drafts.indexWhere((d) => d.id == draftId);
    if (draftIndex == -1) return;

    final draft = _drafts[draftIndex];
    final characters = List<Character>.from(draft.characters);

    final existingIndex = characters.indexWhere((c) => c.id == character.id);
    if (existingIndex != -1) {
      characters[existingIndex] = character;
    } else {
      characters.add(character);
    }

    final updatedDraft = draft.copyWith(
      characters: characters,
      lastModified: DateTime.now(),
    );

    DraftStorageService.saveDraft(updatedDraft);

    setState(() {
      _drafts[draftIndex] = updatedDraft;
      _isAddingCharacter[draftId] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Character saved", textAlign: TextAlign.center),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitCharacterSet(CharacterSetDraft draft) async {
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
        widget.playerId,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create character set",
          style: TextStyle(fontSize: 16, color: theme.tertiary),
        ),
        backgroundColor: theme.primary,
        foregroundColor: theme.tertiary,
        actions: [
          RetroIconButton(
            onPressed: _createNewDraft,
            margin: EdgeInsets.only(right: 6),
            backgroundColor: theme.secondary,
            borderWidth: 3,
            borderColor: theme.tertiary,

            icon: Icons.add,
            iconSize: 30,
            iconColor: theme.tertiary,

            padding: 0,

            tooltip: "Create draft",
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
            ),
          ),

          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                  ),
                )
              : _drafts.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.tertiary.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.primary, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 80,
                          color: theme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No drafts yet",
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tap the + button above to create your first character set!",
                          style: TextStyle(
                            color: theme.secondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: _drafts.map((draft) {
                      final isExpanded = _expandedDraftId == draft.id;
                      final isAddingChar =
                          _isAddingCharacter[draft.id] ?? false;

                      return _buildDraftSection(
                        draft,
                        isExpanded,
                        isAddingChar,
                        theme,
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDraftSection(
    CharacterSetDraft draft,
    bool isExpanded,
    bool isAddingChar,
    ColorScheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.error,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black26),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleDraft(draft.id),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.expand_circle_down_rounded,
                      color: isExpanded
                          ? theme.tertiary
                          : theme.tertiary.withAlpha(200),
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.tertiary.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      draft.isPublic
                          ? Icons.public_rounded
                          : Icons.lock_rounded,
                      color: theme.error,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.name,
                          style: TextStyle(color: theme.tertiary, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              draft.isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_empty_rounded,
                              size: 14,
                              color: draft.isComplete
                                  ? theme.primary
                                  : theme.tertiary.withAlpha(200),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "${draft.characterCount} / 16",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.tertiary.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.tertiary),
                    onSelected: (value) {
                      if (value == "delete") {
                        _deleteDraft(draft);
                      } else if (value == "visibility") {
                        _toggleDraftVisibility(draft);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "visibility",
                        child: Row(
                          children: [
                            Icon(
                              draft.isPublic
                                  ? Icons.lock_rounded
                                  : Icons.public_rounded,
                              size: 20,
                              color: theme.secondary,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              draft.isPublic ? "Make Private" : "Make Public",
                              style: TextStyle(color: theme.secondary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: theme.error,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              "Delete Draft",
                              style: TextStyle(color: theme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipRect(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    ...draft.characters.map(
                                      (character) => SizedBox(
                                        width: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: theme.secondary,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.network(
                                                  character.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        debugPrint(
                                                          character.imageUrl,
                                                        );
                                                        return Container(
                                                          color: theme.primary,
                                                          child: Icon(
                                                            Icons.error,
                                                            color: theme.error,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              character.name,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: theme.tertiary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (!draft.isComplete)
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _isAddingCharacter[draft.id] = true;
                                        }),
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: theme.secondary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: theme.secondary,
                                              width: 3,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_circle_outline_rounded,
                                                color: theme.tertiary,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 4),

                                              Text(
                                                "Add New",
                                                style: TextStyle(
                                                  color: theme.tertiary,
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    if (isAddingChar)
                                      CharacterInputCard(
                                        onSave: (character) =>
                                            _saveCharacter(draft.id, character),
                                        onCancel: () => setState(() {
                                          _isAddingCharacter[draft.id] = false;
                                        }),
                                      ),

                                    if (draft.isComplete && !isAddingChar) ...[
                                      const SizedBox(height: 12),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
