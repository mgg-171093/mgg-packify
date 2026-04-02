import 'package:flutter/foundation.dart';

@immutable
class PackageHistoryEntry {
  const PackageHistoryEntry({
    required this.ticket,
    required this.ambiente,
    required this.iteracion,
    required this.packageName,
    required this.packageDir,
    required this.generatedAt,
    this.huNombre = '',
  });

  final String ticket;
  final String huNombre;
  final String ambiente;
  final String iteracion;
  final String packageName;
  final String packageDir;
  final DateTime generatedAt;

  factory PackageHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PackageHistoryEntry(
        ticket: json['ticket'] as String,
        huNombre: (json['huNombre'] as String?) ?? '',
        ambiente: json['ambiente'] as String,
        iteracion: json['iteracion'] as String,
        packageName: json['packageName'] as String,
        packageDir: json['packageDir'] as String,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'ticket': ticket,
    'huNombre': huNombre,
    'ambiente': ambiente,
    'iteracion': iteracion,
    'packageName': packageName,
    'packageDir': packageDir,
    'generatedAt': generatedAt.toIso8601String(),
  };
}
