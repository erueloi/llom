import 'package:flutter/material.dart';

class ShelfUnit {
  final String id;
  final String name;
  final String location;
  final int shelfCount;
  final int bookCount;
  final int widthCm;
  final IconData icon;

  const ShelfUnit({
    required this.id,
    required this.name,
    this.location = '',
    required this.shelfCount,
    required this.bookCount,
    this.widthCm = 80,
    this.icon = Icons.shelves,
  });

  /// Còpia amb camps modificats
  ShelfUnit copyWith({
    String? id,
    String? name,
    String? location,
    int? shelfCount,
    int? bookCount,
    int? widthCm,
    IconData? icon,
  }) {
    return ShelfUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      shelfCount: shelfCount ?? this.shelfCount,
      bookCount: bookCount ?? this.bookCount,
      widthCm: widthCm ?? this.widthCm,
      icon: icon ?? this.icon,
    );
  }
}
