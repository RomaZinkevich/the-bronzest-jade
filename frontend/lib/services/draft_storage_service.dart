import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:guess_who/models/character_set_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraftStorageService {
  static const String _draftsKey = "character_set_drafts";

  static Future<List<CharacterSetDraft>> loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftsKey);

      if (draftJson == null) return [];

      final List<dynamic> draftsList = json.decode(draftJson);
      return draftsList
          .map((d) => CharacterSetDraft.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error loading drafts: $e");
      return [];
    }
  }

  static Future<void> saveDrafts(List<CharacterSetDraft> drafts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = json.encode(drafts.map((d) => d.toJson()).toList());
      await prefs.setString(_draftsKey, draftsJson);
    } catch (e) {
      debugPrint("Error saving drafts: $e");
    }
  }

  static Future<void> saveDraft(CharacterSetDraft draft) async {
    final drafts = await loadDrafts();
    final index = drafts.indexWhere((d) => d.id == draft.id);

    if (index != -1) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }

    await saveDrafts(drafts);
  }

  static Future<void> deleteDraft(String draftId) async {
    final drafts = await loadDrafts();
    drafts.removeWhere((d) => d.id == draftId);

    await saveDrafts(drafts);
  }
}
