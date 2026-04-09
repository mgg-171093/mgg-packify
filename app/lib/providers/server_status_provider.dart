import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ServerStatus { starting, ready, error, crashed, restarting }

final serverStatusProvider = StateProvider<ServerStatus>(
  (ref) => ServerStatus.starting,
);
