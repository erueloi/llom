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
  final List<int>? box;
  final String? synopsis;
  final String? coverUrl;
  final int? pageCount;
  final String? publishedYear;
  final String? infoUrl;
  final int enrichmentAttempts;
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
    this.box,
    this.synopsis,
    this.coverUrl,
    this.pageCount,
    this.publishedYear,
    this.infoUrl,
    this.enrichmentAttempts = 0,
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
      if (box != null) 'box': box,
      if (synopsis != null) 'synopsis': synopsis,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (pageCount != null) 'pageCount': pageCount,
      if (publishedYear != null) 'publishedYear': publishedYear,
      if (infoUrl != null) 'infoUrl': infoUrl,
      if (enrichmentAttempts > 0) 'enrichmentAttempts': enrichmentAttempts,
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
      box: (map['box'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
      synopsis: map['synopsis'] as String?,
      coverUrl: map['coverUrl'] as String?,
      pageCount: (map['pageCount'] as num?)?.toInt(),
      publishedYear: map['publishedYear'] as String?,
      infoUrl: map['infoUrl'] as String?,
      enrichmentAttempts: (map['enrichmentAttempts'] as num?)?.toInt() ?? 0,
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
    List<int>? box,
    String? synopsis,
    String? coverUrl,
    int? pageCount,
    String? publishedYear,
    String? infoUrl,
    int? enrichmentAttempts,
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
      box: box ?? this.box,
      synopsis: synopsis ?? this.synopsis,
      coverUrl: coverUrl ?? this.coverUrl,
      pageCount: pageCount ?? this.pageCount,
      publishedYear: publishedYear ?? this.publishedYear,
      infoUrl: infoUrl ?? this.infoUrl,
      enrichmentAttempts: enrichmentAttempts ?? this.enrichmentAttempts,
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
          synopsis == other.synopsis &&
          coverUrl == other.coverUrl &&
          pageCount == other.pageCount &&
          publishedYear == other.publishedYear &&
          infoUrl == other.infoUrl &&
          enrichmentAttempts == other.enrichmentAttempts &&
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
      synopsis.hashCode ^
      coverUrl.hashCode ^
      pageCount.hashCode ^
      publishedYear.hashCode ^
      infoUrl.hashCode ^
      enrichmentAttempts.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, author: $author, shelfCode: $shelfCode, bookcaseId: $bookcaseId, positionIndex: $positionIndex, photoUrl: $photoUrl, notes: $notes, box: $box, synopsis: $synopsis, coverUrl: $coverUrl, pageCount: $pageCount, publishedYear: $publishedYear, infoUrl: $infoUrl, enrichmentAttempts: $enrichmentAttempts, createdAt: $createdAt)';
  }
}
