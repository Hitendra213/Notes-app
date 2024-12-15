// lib/note_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'note.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesString = prefs.getString('notes');

    if (notesString != null) {
      List<dynamic> notesJson = jsonDecode(notesString);
      _notes = notesJson.map((note) => Note(
        title: note['title'],
        content: note['content'],
        category: note['category'],
        tags: List<String>.from(note['tags']),
        isFavorite: note['isFavorite'],
      )).toList();
      notifyListeners();
    }
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
  }

  Future<void> updateNote(int index, Note note) async {
    _notes[index] = note;
    await _saveNotes();
  }

  Future<void> deleteNote(int index) async {
    _notes.removeAt(index);
    await _saveNotes();
  }

  Future<void> toggleFavorite(int index) async {
    _notes[index].isFavorite = !_notes[index].isFavorite;
    await _saveNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    String notesString = jsonEncode(_notes.map((note) => note.toMap()).toList());
    await prefs.setString('notes', notesString);
    notifyListeners();
  }
}
