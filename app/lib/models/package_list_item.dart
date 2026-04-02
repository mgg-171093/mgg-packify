import 'package:flutter/foundation.dart';

@immutable
class PackageListItem {
  const PackageListItem({
    required this.name,
    required this.path,
    required this.hasMeta,
    this.createdAt,
  });

  final String name;
  final String path;
  final bool hasMeta;
  final DateTime? createdAt;

  factory PackageListItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawDate = json['created_at'];
    if (rawDate != null) {
      try {
        createdAt = DateTime.parse(rawDate.toString());
      } catch (_) {
        createdAt = null;
      }
    }
    return PackageListItem(
      name: (json['name'] as String?) ?? '',
      path: (json['path'] as String?) ?? '',
      hasMeta: (json['has_meta'] as bool?) ?? false,
      createdAt: createdAt,
    );
  }
}
