import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'note.dart';
import 'note_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NoteProvider(),
      child: MaterialApp(
        title: 'Notes App',
        theme: ThemeData.light().copyWith(
          primaryColor: Colors.blue,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: Colors.blueGrey,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blueAccent,
          ),
        ),
        themeMode: _themeMode,
        home: NotesList(
          onThemeChanged: (ThemeMode mode) {
            setState(() {
              _themeMode = mode;
            });
          },
        ),
      ),
    );
  }
}

class NotesList extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  NotesList({required this.onThemeChanged});

  @override
  _NotesListState createState() => _NotesListState();
}

class _NotesListState extends State<NotesList> {
  String _searchQuery = '';
  bool _showFavorites = false;
  String _sortOption = 'title'; // New variable for sorting

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final filteredNotes = provider.notes.where((note) {
      return (_showFavorites ? note.isFavorite : true) &&
          (note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    // Sort notes based on the selected option
    filteredNotes.sort((a, b) {
      if (_sortOption == 'date') {
        return b.createdAt.compareTo(a.createdAt); // Sort by date
      }
      return a.title.compareTo(b.title); // Default to sort by title
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes', style: TextStyle(fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: _showFavorites ? Colors.red : Colors.white),
            onPressed: () {
              setState(() {
                _showFavorites = !_showFavorites;
              });
            },
          ),
          // Theme toggle button
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              widget.onThemeChanged(
                Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          // Sort options button
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return {'title', 'date'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice[0].toUpperCase() + choice.substring(1)),
                );
              }).toList();
            },
            icon: Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(note.content),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NoteForm(note: note, index: provider.notes.indexOf(note))),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            provider.toggleFavorite(provider.notes.indexOf(note));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: note.isFavorite ? Colors.red : Colors.transparent,
                              border: Border.all(
                                color: note.isFavorite ? Colors.red : Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.favorite,
                                color: note.isFavorite ? Colors.white : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            Share.share('${note.title}\n\n${note.content}');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text('Are you sure you want to delete this note?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('Delete'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmDelete) {
                              provider.deleteNote(provider.notes.indexOf(note));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteForm()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteForm extends StatefulWidget {
  final Note? note;
  final int? index;

  NoteForm({this.note, this.index});

  @override
  _NoteFormState createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _categoryController.text = widget.note!.category;
      _tagsController.text = widget.note!.tags.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
              maxLines: 5,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(widget.note == null ? 'Add Note' : 'Update Note'),
              onPressed: () {
                List<String> tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
                if (widget.note == null) {
                  provider.addNote(Note(
                    title: _titleController.text,
                    content: _contentController.text,
                    category: _categoryController.text,
                    tags: tags,
                    createdAt: DateTime.now(),
                  ));
                } else {
                  provider.updateNote(widget.index!, Note(
                    title: _titleController.text,
                    content: _contentController.text,
                    category: _categoryController.text,
                    tags: tags,
                    isFavorite: widget.note!.isFavorite,
                    createdAt: widget.note!.createdAt, // Keep the original creation date
                  ));
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
