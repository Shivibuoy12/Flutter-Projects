import 'dart:io';

import 'package:flutter/foundation.dart';

/// Loads `Downloads/fmx_instruments.json` (Windows: `%USERPROFILE%\Downloads`).
Future<String?> readDownloadsFmxInstrumentsJsonString() async {
  if (kIsWeb) {
    return null;
  }
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return null;
  }
  final sep = Platform.pathSeparator;
  final basenames = [
    'fmx_instruments.json',
    'FMX_Instruments.json',
  ];

  for (final basename in basenames) {
    final path = '$home${sep}Downloads$sep$basename';
    final f = File(path);
    try {
      if (await f.exists()) {
        return await f.readAsString();
      }
    } catch (e, st) {
      debugPrint('Downloads fetch $path failed: $e\n$st');
    }
  }

  return null;
}
