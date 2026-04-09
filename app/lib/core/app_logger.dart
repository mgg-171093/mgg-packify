import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

class RotatingFileOutput extends LogOutput {
  final String filePath;
  final int maxSizeBytes;
  final int maxBackups;
  IOSink? _sink;
  File? _file;
  int _currentSize = 0;

  RotatingFileOutput({
    required this.filePath,
    this.maxSizeBytes = 5 * 1024 * 1024, // 5 MB
    this.maxBackups = 3,
  });

  @override
  Future<void> init() async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    _file = file;
    _currentSize = file.existsSync() ? await file.length() : 0;
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) {
    final lines = event.lines.join('\n') + '\n';
    final bytes = lines.length;
    if (_currentSize + bytes > maxSizeBytes) {
      _rotate();
    }
    _sink?.write(lines);
    _currentSize += bytes;
  }

  void _rotate() {
    _sink?.close();
    final base = _file!.path;
    // shift backups: .3 → delete, .2 → .3, .1 → .2, current → .1
    for (var i = maxBackups; i >= 1; i--) {
      final old = File('$base.$i');
      if (old.existsSync()) {
        if (i == maxBackups) {
          old.deleteSync();
        } else {
          old.renameSync('$base.${i + 1}');
        }
      }
    }
    _file!.renameSync('$base.1');
    _file = File(base);
    _sink = _file!.openWrite(mode: FileMode.write);
    _currentSize = 0;
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}

class AppLogger {
  static AppLogger? _instance;
  static late Logger _logger;
  static late String _logFilePath;

  AppLogger._();

  static Future<AppLogger> initialize() async {
    if (_instance != null) return _instance!;

    // Resolve log directory: %LOCALAPPDATA%\MGG Packify\logs\
    final localAppData =
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['HOME'] ??
        '.';
    final logDir = p.join(localAppData, 'MGG Packify', 'logs');
    _logFilePath = p.join(logDir, 'app.log');

    final output = RotatingFileOutput(filePath: _logFilePath);
    await output.init();

    _logger = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(printTime: true, colors: false),
      output: MultiOutput([ConsoleOutput(), output]),
    );

    _instance = AppLogger._();
    return _instance!;
  }

  static String get logFilePath => _logFilePath;

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  // Write raw line (used for python stdout capture)
  static void raw(String line) => _logger.i('[python-stdout] $line');
}
