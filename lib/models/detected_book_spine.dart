/// Model que representa un llom de llibre detectat per visió artificial (Gemini Flash)
class DetectedBookSpine {
  final String id;
  String title;
  String? author;

  /// Coordenades normalitzades de 0 a 1000: [ymin, xmin, ymax, xmax]
  List<int> box;

  /// Indica si la caixa ha estat traçada manualment per l'usuari
  final bool isManual;

  DetectedBookSpine({
    required this.id,
    required this.title,
    this.author,
    required this.box,
    this.isManual = false,
  });

  int get ymin => box.isNotEmpty ? box[0] : 0;
  int get xmin => box.length > 1 ? box[1] : 0;
  int get ymax => box.length > 2 ? box[2] : 1000;
  int get xmax => box.length > 3 ? box[3] : 1000;

  DetectedBookSpine copyWith({
    String? id,
    String? title,
    String? author,
    List<int>? box,
    bool? isManual,
  }) {
    return DetectedBookSpine(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      box: box ?? List<int>.from(this.box),
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'box': box,
      if (isManual) 'isManual': true,
    };
  }

  factory DetectedBookSpine.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawBox = (map['box_2d'] ?? map['box']) as List<dynamic>? ?? [0, 0, 1000, 1000];
    final normalizedBox = rawBox.map((e) {
      if (e is num) return e.toInt().clamp(0, 1000);
      return 0;
    }).toList();

    // Assegurem que tingui exactament 4 elements [ymin, xmin, ymax, xmax]
    while (normalizedBox.length < 4) {
      normalizedBox.add(1000);
    }

    final rawTitle = ((map['label'] ?? map['title']) as String?)?.trim() ?? '';
    final title = rawTitle.isEmpty ? 'Sense títol' : rawTitle;
    final rawAuthor = (map['author'] as String?)?.trim();
    final author = (rawAuthor != null && rawAuthor.isNotEmpty) ? rawAuthor : null;
    final isManual = map['isManual'] == true;

    return DetectedBookSpine(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      author: author,
      box: normalizedBox.sublist(0, 4),
      isManual: isManual,
    );
  }

  @override
  String toString() {
    return 'DetectedBookSpine(id: $id, title: "$title", author: "$author", box: $box, isManual: $isManual)';
  }
}
