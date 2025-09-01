import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  final String text;
  final String author;
  bool isFavorite;

  Quote({
    required this.text,
    required this.author,
    this.isFavorite = false,
  });

  /// Unique stable ID based on quote text hash
  String get id => text.hashCode.toString();

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quote(
      text: data['text'] ?? '',
      author: data['author'] ?? '',
      isFavorite: true,
    );
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['content'] ?? json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'author': author,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          author == other.author;

  @override
  int get hashCode => text.hashCode ^ author.hashCode;
}
