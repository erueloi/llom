import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String shelfCode;
  final String? bookcaseId;
  final int positionIndex;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.shelfCode,
    this.bookcaseId,
    required this.positionIndex,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  /// Converteix el model en un Map compatible amb Cloud Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'shelfCode': shelfCode,
      'bookcaseId': bookcaseId,
      'positionIndex': positionIndex,
      'photoUrl': photoUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea una instància de BookModel a partir d'un document de Firestore
  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      shelfCode: map['shelfCode'] as String? ?? '',
      bookcaseId: map['bookcaseId'] as String?,
      positionIndex: (map['positionIndex'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Retorna una còpia del model amb els camps actualitzats
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? shelfCode,
    String? bookcaseId,
    int? positionIndex,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      shelfCode: shelfCode ?? this.shelfCode,
      bookcaseId: bookcaseId ?? this.bookcaseId,
      positionIndex: positionIndex ?? this.positionIndex,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          author == other.author &&
          shelfCode == other.shelfCode &&
          bookcaseId == other.bookcaseId &&
          positionIndex == other.positionIndex &&
          photoUrl == other.photoUrl &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      author.hashCode ^
      shelfCode.hashCode ^
      bookcaseId.hashCode ^
      positionIndex.hashCode ^
      photoUrl.hashCode ^
      notes.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, author: $author, shelfCode: $shelfCode, bookcaseId: $bookcaseId, positionIndex: $positionIndex, photoUrl: $photoUrl, notes: $notes, createdAt: $createdAt)';
  }
}
