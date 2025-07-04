import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
// import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
// import 'package:analyzer/dart/analysis/results.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as p;
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service_factory.dart';

final AnalyzerWrapperService _analyzerWrapperService =
    AnalyzerWrapperServiceFactory
        .create(); // Use the appropriate version for your tests
StreamSubscription<LogRecord>? _currentSubscription;

void setupTestLogging({Level level = Level.WARNING}) {
  // Set up logging to show warnings and above
  Logger.root.level = level;
  if (_currentSubscription != null) {
    _currentSubscription!.cancel();
  }
  _currentSubscription = Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
}

Future<(LibraryElem library, String path)> analyzeTestFile(
    String filename) async {
  // Get the path to the test file relative to the project root
  final testFilePath = p.normalize(p.absolute(
    p.join('test', 'fixtures', filename),
  ));

  // Ensure the file exists
  if (!File(testFilePath).existsSync()) {
    throw Exception(
        'Test file not found at $testFilePath. Current directory: ${Directory.current.path}');
  }

  // Set up analysis context - use the fixtures directory
  final fixturesDir = p.dirname(testFilePath);
  final libraryElem =
      await _analyzerWrapperService.loadLibrary(fixturesDir, testFilePath);

  // Get class elements
  return (libraryElem, testFilePath);
}
