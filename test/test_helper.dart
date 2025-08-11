import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
// import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
// import 'package:analyzer/dart/analysis/results.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as p;
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service_factory.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:build_test/build_test.dart';

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

/// Analyzes source code from a string and returns LibraryElem for testing validation logic
/// without requiring physical files.
Future<LibraryElem> analyzeStringCode(String sourceCode, {String fileName = 'test.dart'}) async {
  // Create a temporary directory for the string-based analysis
  final tempDir = Directory.systemTemp.createTempSync('rdf_mapper_string_test_');
  
  try {
    // Write the source code to a temporary file
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsString(sourceCode);
    
    // Use the existing loadLibrary method to analyze the temporary file
    final libraryElem = await _analyzerWrapperService.loadLibrary(tempDir.path, tempFile.path);
    
    return libraryElem;
  } finally {
    // Clean up the temporary directory
    try {
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      // Ignore cleanup errors in tests
    }
  }
}

/// Builds template data from source code string, useful for testing validation logic
/// and template generation without requiring physical files.
/// 
/// This method will throw ValidationException if there are validation errors,
/// which is exactly what we want to test in validation tests.
Future<FileTemplateData> buildTemplateDataFromString(
    String sourceCode, {
    String fileName = 'test.dart',
    String packageName = 'test'}) async {
  
  // Analyze the source code to get LibraryElem
  final library = await analyzeStringCode(sourceCode, fileName: fileName);
  
  // Extract classes and enums from the library
  final classes = library.classes;
  final enums = library.enums;
  
  // Create broader imports from the library
  final broaderImports = BroaderImports.create(library);
  
  // Use BuilderHelper to build template data
  // This will throw ValidationException if there are validation errors
  final builderHelper = BuilderHelper();
  final templateData = await builderHelper.buildTemplateData(
    fileName,
    packageName,
    classes,
    enums,
    broaderImports,
  );
  
  if (templateData == null) {
    throw Exception('Template data was null but no validation exception was thrown');
  }
  
  return templateData;
}

Future<AssetReader> createTestAssetReader() async {
  final readerWriter = TestReaderWriter();
  await readerWriter.testing.loadIsolateSources();
  return readerWriter;
}
