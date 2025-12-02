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
  CharacterSetDraft? _currentDraft;

  final TextEditingController _draftNameController = TextEditingController();

  bool _isLoading = false;
  bool _isDraftExpanded = false;
  bool _isAddingCharacter = false;
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
            _currentDraft = draft;
            _drafts.add(draft);
            _isDraftExpanded = false;
            _isAddingCharacter = true;
          });

          debugPrint("name: ${draft.name}, public: ${draft.isPublic}");
          DraftStorageService.saveDraft(draft);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _selectDraft(CharacterSetDraft draft) {
    setState(() {
      _currentDraft = draft;
      _isDraftExpanded = false;
      _isAddingCharacter = false;
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
      if (_currentDraft?.id == draft.id) {
        _currentDraft = null;
        _isAddingCharacter = false;
      }
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

      if (_currentDraft?.id == draft.id) {
        _currentDraft = updated;
      }
    });
  }

  void _saveCharacter(Character character) {
    if (_currentDraft == null) return;

    final characters = List<Character>.from(_currentDraft!.characters);
    final existingIndex = characters.indexWhere((c) => c.id == character.id);

    if (existingIndex != -1) {
      characters[existingIndex] = character;
    } else {
      characters.add(character);
    }

    final updatedDraft = _currentDraft!.copyWith(
      characters: characters,
      lastModified: DateTime.now(),
    );

    DraftStorageService.saveDraft(updatedDraft);

    setState(() {
      final index = _drafts.indexWhere((d) => d.id == updatedDraft.id);

      if (index != -1) {
        _drafts[index] = updatedDraft;
      }

      _currentDraft = updatedDraft;
      _isAddingCharacter = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Character saved", textAlign: TextAlign.center),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _submitCharacterSet() async {
    if (_currentDraft == null || !_currentDraft!.isComplete) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final characterData = _currentDraft!.characters
          .map((c) => {"name": c.name, "imageUrl": c.imageUrl})
          .toList();

      await ApiService.createCharacterSet(
        _currentDraft!.name,
        widget.playerId,
        _currentDraft!.isPublic,
        characterData,
      );

      await DraftStorageService.deleteDraft(_currentDraft!.id);

      setState(() {
        _drafts.removeWhere((d) => d.id == _currentDraft!.id);
        _currentDraft = null;
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

          Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.error,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => setState(() {
                    _isDraftExpanded = !_isDraftExpanded;
                  }),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _isDraftExpanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.expand_circle_down_outlined,
                          color: theme.tertiary,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "Character Drafts (${_drafts.length})",
                        style: TextStyle(color: theme.tertiary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: _isDraftExpanded ? null : 0,
                        child: _isDraftExpanded
                            ? Column(
                                children: [
                                  if (_isLoading)
                                    Padding(
                                      padding: const EdgeInsets.all(40),
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.primary,
                                            ),
                                        strokeWidth: 5,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    )
                                  else if (_drafts.isEmpty)
                                    Container(
                                      margin: const EdgeInsets.all(15),
                                      padding: const EdgeInsets.all(40),
                                      decoration: BoxDecoration(
                                        color: theme.tertiary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "No drafts yet. Create one to get started!",
                                        style: TextStyle(
                                          color: theme.secondary,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  else
                                    ..._drafts.map(
                                      (draft) => DraftListItem(
                                        draft: draft,
                                        onTap: () => _selectDraft(draft),
                                        onDelete: () => _deleteDraft(draft),
                                        onToggleVisibility: () =>
                                            _toggleDraftVisibility(draft),
                                      ),
                                    ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      if (_currentDraft != null) ...[
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.secondary,
                            border: Border.all(color: theme.tertiary, width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _currentDraft!.name,
                                      style: TextStyle(
                                        color: theme.tertiary,
                                        fontSize: 20,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _currentDraft!.isComplete
                                          ? Colors.green
                                          : theme.tertiary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${_currentDraft!.characterCount} / 16",
                                      style: TextStyle(
                                        color: _currentDraft!.isComplete
                                            ? theme.tertiary
                                            : theme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.start,
                                children: [
                                  ..._currentDraft!.characters.map(
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
                                ],
                              ),

                              if (!_currentDraft!.isComplete)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isAddingCharacter = true;
                                  }),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: theme.primary.withAlpha(150),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.secondary,
                                        width: 3,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: theme.tertiary,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "ADD NEW",
                                          style: TextStyle(
                                            color: theme.tertiary,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (_isAddingCharacter)
                          CharacterInputCard(
                            onSave: _saveCharacter,
                            onCancel: () => setState(() {
                              _isAddingCharacter = false;
                            }),
                          ),

                        if (_currentDraft!.isComplete &&
                            !_isAddingCharacter) ...[
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: RetroButton(
                              text: _isSubmitting
                                  ? "SUBMITTING..."
                                  : "SUBMIT SET",
                              fontSize: 20,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 40,
                              ),
                              backgroundColor: Colors.green,
                              foregroundColor: theme.tertiary,
                              icon: _isSubmitting
                                  ? Icons.hourglass_empty
                                  : Icons.upload_rounded,
                              iconSize: 28,
                              iconAtEnd: true,
                              onPressed: _isSubmitting
                                  ? () {}
                                  : _submitCharacterSet,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
