import 'package:flutter/foundation.dart';

@immutable
class PackageTemplate {
  const PackageTemplate({
    required this.name,
    required this.selectedTypes,
    required this.instancesJson,
  });

  final String name;
  final List<String> selectedTypes; // ComponentType key strings
  final List<Map<String, dynamic>> instancesJson; // serialized instances

  factory PackageTemplate.fromJson(Map<String, dynamic> json) =>
      PackageTemplate(
        name: json['name'] as String,
        selectedTypes: List<String>.from(json['selectedTypes'] as List),
        instancesJson: List<Map<String, dynamic>>.from(
          (json['instancesJson'] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'selectedTypes': selectedTypes,
    'instancesJson': instancesJson,
  };
}
