class Note {
  String title;
  String content;
  String category; // New field for category
  List<String> tags; // New field for tags
  bool isFavorite; // New field for favorite status
  DateTime createdAt; // New field for creation date

  Note({
    required this.title,
    required this.content,
    this.category = '',
    this.tags = const [],
    this.isFavorite = false,
    DateTime? createdAt, // Optional parameter
  }) : createdAt = createdAt ?? DateTime.now(); // Default to now if not provided

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to String for storage
    };
  }

  @override
  String toString() {
    return 'Note{title: $title, content: $content, category: $category, tags: $tags, isFavorite: $isFavorite, createdAt: $createdAt}';
  }
}
