import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

/// Internal class to hold processing results during template data building
class _ProcessingResult {
  final List<Map<String, dynamic>> mappers;
  final Set<Map<String, String>> imports;
  final Set<Map<String, String>> modelImports;
  final Map<String, Map<String, dynamic>> providers;
  final Map<String, Map<String, dynamic>> namedIriMappers;

  _ProcessingResult({
    required this.mappers,
    required this.imports,
    required this.modelImports,
    required this.providers,
    required this.namedIriMappers,
  });
}

class InitFileBuilderHelper {
  static final _templateRenderer = TemplateRenderer();
  final Logger log = Logger('InitFileBuilderHelper');

  InitFileBuilderHelper();

  Map<String, dynamic>? buildTemplateData(
      List<(String path, String package, String content)> jsonFiles,
      {required bool isTest,
      required String outputPath}) {
    try {
      final sortedJsonFiles = _sortJsonFiles(jsonFiles);
      final processingResult =
          _processJsonFiles(sortedJsonFiles, isTest, outputPath);

      return _buildFinalTemplateData(processingResult, isTest);
    } catch (e, stackTrace) {
      log.severe('Error building template data: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Sorts JSON files by package and path for consistent processing order
  List<(String path, String package, String content)> _sortJsonFiles(
      List<(String path, String package, String content)> jsonFiles) {
    return List.from(jsonFiles)
      ..sort((a, b) {
        final (aPath, aPackage, _) = a;
        final (bPath, bPackage, _) = b;
        final cmp = aPackage.compareTo(bPackage);
        if (cmp != 0) return cmp;
        return aPath.compareTo(bPath);
      });
  }

  /// Processes all JSON files and extracts mapper information
  _ProcessingResult _processJsonFiles(
      List<(String path, String package, String content)> sortedJsonFiles,
      bool isTest,
      String outputPath) {
    final mappers = <Map<String, dynamic>>[];
    final imports = <Map<String, String>>{};
    final modelImports = <Map<String, String>>{};
    final providers = <String, Map<String, dynamic>>{};
    final namedIriMappers = <String, Map<String, dynamic>>{};

    int importIndex = -1;
    for (final file in sortedJsonFiles) {
      importIndex++;
      final (path, package, content) = file;

      try {
        final jsonData = jsonDecode(content) as Map<String, dynamic>;
        final modelImportPath = path.replaceAll('.rdf_mapper.cache.json', '');

        // Process mappers and context providers from this file
        _processFileMappers(jsonData, modelImportPath, importIndex, mappers,
            providers, namedIriMappers);

        // Add imports for this file
        _addImportsForFile(modelImportPath, package, importIndex, isTest,
            outputPath, imports, modelImports);
      } catch (e) {
        log.warning('Error processing cache file $path: $e');
      }
    }

    return _ProcessingResult(
      mappers: mappers,
      imports: imports,
      modelImports: modelImports,
      providers: providers,
      namedIriMappers: namedIriMappers,
    );
  }

  /// Processes mappers and context providers from a single JSON file
  void _processFileMappers(
      Map<String, dynamic> jsonData,
      String modelImportPath,
      int importIndex,
      List<Map<String, dynamic>> mappers,
      Map<String, Map<String, dynamic>> providers,
      Map<String, Map<String, dynamic>> namedIriMappers) {
    final mappersData = jsonData['mappers'] as List? ?? [];

    for (final mapperData in mappersData.cast<Map<String, dynamic>>()) {
      final className = mapperData['className'] as String?;
      final mapperClassName = mapperData['mapperClassName'] as String?;

      if (className == null || mapperClassName == null) continue;

      // Extract context providers for this mapper
      final contextProviders = _extractContextProviders(mapperData);
      _collectContextProviders(contextProviders, providers);

      // Extract IRI mappers for this mapper
      final iriMapperInfo = _extractIriMappers(mapperData);
      _collectIriMappers(iriMapperInfo, namedIriMappers);

      // Check if this mapper should be registered globally
      final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;

      if (registerGlobally) {
        mappers.add({
          'name': mapperClassName,
          'type': className,
          '_importPath': modelImportPath,
          '_importIndex': importIndex,
          'hasContextProviders': contextProviders.isNotEmpty,
          'contextProviders': contextProviders,
          'hasIriMappers': iriMapperInfo.isNotEmpty,
          'iriMappers': iriMapperInfo,
        });
      }
    }
  }

  /// Extracts context providers from mapper data
  List<Map<String, dynamic>> _extractContextProviders(
      Map<String, dynamic> mapperData) {
    return (mapperData['contextProviders'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  /// Collects context providers into the providers map
  void _collectContextProviders(List<Map<String, dynamic>> contextProviders,
      Map<String, Map<String, dynamic>> providers) {
    for (final ct in contextProviders) {
      final provider = ct['value'] as Map<String, dynamic>;
      final variableName = provider['variableName'] as String?;
      final parameterName = provider['parameterName'] as String?;
      final placeholder = provider['placeholder'] as String?;
      final privateFieldName = provider['privateFieldName'] as String?;

      if (variableName != null &&
          parameterName != null &&
          placeholder != null &&
          privateFieldName != null) {
        providers[variableName] = {
          'variableName': variableName,
          'parameterName': parameterName,
          'placeholder': placeholder,
          'privateFieldName': privateFieldName,
          'type': 'String', // Default type, can be extended if needed
        };
      }
    }
  }

  /// Extracts IRI mappers from mapper data
  List<Map<String, dynamic>> _extractIriMappers(
      Map<String, dynamic> mapperData) {
    final iriStrategy = mapperData['iriStrategy'] as Map<String, dynamic>?;
    if (iriStrategy == null) return [];

    final mapper = iriStrategy['mapper'] as Map<String, dynamic>?;
    if (mapper == null) return [];
    print("Extracting IRI mapper: $mapper");
    // Extract IRI mapper type and name information
    final type = mapper['type'] as String?;
    final name = mapper['name'] as String?;
    final implementationType = mapper['implementationType'] as String?;
    final isNamed = mapper['isNamed'] as bool? ?? false;
    final isTypeBased = mapper['isTypeBased'] as bool? ?? false;
    final isInstance = mapper['isInstance'] as bool? ?? false;
    final instanceInitializationCode =
        mapper['instanceInitializationCode'] as String?;
    if (type == null) return [];
    String? code;
    if (isTypeBased) {
      code = '$implementationType()';
    } else if (isInstance) {
      code = instanceInitializationCode;
    }
    if (code == null) {
      code = name;
    }
    if (code == null) {
      throw ArgumentError('No valid code found for IRI mapper: $mapper');
    }
    return [
      {
        'type': type,
        'code': code,
        'parameterName': 'iriMapper',
        'isNamed': isNamed,
        'isTypeBased': isTypeBased,
        'isInstance': isInstance,
        'name': name,
      }
    ];
  }

  /// Collects IRI mappers into the iriMappers map
  void _collectIriMappers(List<Map<String, dynamic>> iriMapperInfos,
      Map<String, Map<String, dynamic>> iriMappers) {
    for (final info in iriMapperInfos) {
      final name = info['name'] as String?;
      if (name != null && name.isNotEmpty) {
        iriMappers[name] = info;
      }
    }
  }

  /// Adds import statements for a processed file
  void _addImportsForFile(
      String modelImportPath,
      String package,
      int importIndex,
      bool isTest,
      String outputPath,
      Set<Map<String, String>> imports,
      Set<Map<String, String>> modelImports) {
    if (isTest) {
      _addTestImports(
          modelImportPath, outputPath, importIndex, imports, modelImports);
    } else if (!modelImportPath.startsWith('package:')) {
      _addPackageImports(
          modelImportPath, package, importIndex, imports, modelImports);
    } else {
      _addAbsoluteImports(modelImportPath, importIndex, imports, modelImports);
    }
  }

  /// Adds imports for test files (relative imports)
  void _addTestImports(
      String modelImportPath,
      String outputPath,
      int importIndex,
      Set<Map<String, String>> imports,
      Set<Map<String, String>> modelImports) {
    var relativePath = p.relative(modelImportPath, from: p.dirname(outputPath));
    if (relativePath == '.') {
      // If the file is in the same directory, just use the filename
      relativePath = p.basename(modelImportPath);
    }

    imports.add({
      'value': '$relativePath.rdf_mapper.g.dart',
      'index': importIndex.toString()
    });
    modelImports
        .add({'value': '$relativePath.dart', 'index': importIndex.toString()});
  }

  /// Adds package imports for non-test files
  void _addPackageImports(
      String modelImportPath,
      String package,
      int importIndex,
      Set<Map<String, String>> imports,
      Set<Map<String, String>> modelImports) {
    final fullImportPath =
        'package:$package/${p.relative(modelImportPath, from: 'lib')}';

    imports.add({
      'value': '$fullImportPath.rdf_mapper.g.dart',
      'index': importIndex.toString()
    });
    modelImports.add(
        {'value': '$fullImportPath.dart', 'index': importIndex.toString()});
  }

  /// Adds absolute package imports
  void _addAbsoluteImports(String modelImportPath, int importIndex,
      Set<Map<String, String>> imports, Set<Map<String, String>> modelImports) {
    imports.add({
      'value': '$modelImportPath.rdf_mapper.g.dart',
      'index': importIndex.toString()
    });
    modelImports.add(
        {'value': '$modelImportPath.dart', 'index': importIndex.toString()});
  }

  /// Builds the final template data from processing results
  Map<String, dynamic> _buildFinalTemplateData(
      _ProcessingResult result, bool isTest) {
    final sortedProviders = _sortProviders(result.providers);
    final sortedNamedIriMappers = _sortIriMappers(result.namedIriMappers);
    final sortedImports = _sortImports(result.imports);
    final sortedModelImports = _sortImports(result.modelImports);

    return {
      'generatedOn': DateTime.now().toIso8601String(),
      'isTest': isTest,
      'mappers': result.mappers,
      'imports': sortedImports,
      'model_imports': sortedModelImports,
      'providers': sortedProviders,
      'hasProviders': sortedProviders.isNotEmpty,
      'iriMappers': sortedNamedIriMappers,
      'hasIriMappers': sortedNamedIriMappers.isNotEmpty,
    };
  }

  /// Sorts providers by parameter name for consistent ordering
  List<Map<String, dynamic>> _sortProviders(
      Map<String, Map<String, dynamic>> providers) {
    return providers.values.toList()
      ..sort((a, b) => (a['parameterName'] as String)
          .compareTo(b['parameterName'] as String));
  }

  /// Sorts IRI mappers by parameter name for consistent ordering
  List<Map<String, dynamic>> _sortIriMappers(
      Map<String, Map<String, dynamic>> iriMappers) {
    return iriMappers.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  /// Sorts imports by value for consistent ordering
  List<Map<String, String>> _sortImports(Set<Map<String, String>> imports) {
    return imports.toList()..sort((a, b) => a['value']!.compareTo(b['value']!));
  }

  Future<String> build(
    List<(String path, String package, String content)> jsonFiles,
    AssetReader reader, {
    required bool isTest,
    required String outputPath,
  }) async {
    final templateData = buildTemplateData(
      jsonFiles,
      isTest: isTest,
      outputPath: outputPath,
    );
    if (templateData == null) {
      return '';
    }

    return await _templateRenderer.renderInitFileTemplate(templateData, reader);
  }
}
