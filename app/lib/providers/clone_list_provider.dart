import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/package_list_item.dart';

final cloneListProvider = FutureProvider.family<List<PackageListItem>, String>((
  ref,
  baseDir,
) async {
  if (baseDir.isEmpty) return [];
  return ref.read(apiClientProvider).listPackages(baseDir);
});
