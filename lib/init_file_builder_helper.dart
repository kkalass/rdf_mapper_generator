import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

/// Internal class to hold processing results during template data building
class _ProcessingResult {
  final List<Map<String, dynamic>> mappers;
  final Set<Map<String, dynamic>> imports;
  final Set<Map<String, dynamic>> modelImports;
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
      required String outputPath,
      required String currentPackage}) {
    try {
      final sortedJsonFiles = _sortJsonFiles(jsonFiles);
      final processingResult =
          _processJsonFiles(sortedJsonFiles, isTest, outputPath);

      return _buildFinalTemplateData(processingResult, isTest, currentPackage);
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
    final imports = <Map<String, dynamic>>{};
    final modelImports = <Map<String, dynamic>>{};
    final providers = <String, Map<String, dynamic>>{};
    final namedIriMappers = <String, Map<String, dynamic>>{};

    int importIndex = -1;
    for (final file in sortedJsonFiles) {
      importIndex++;
      final (path, package, content) = file;

      try {
        var jsonData = jsonDecode(content) as Map<String, dynamic>;

        final modelImportPath = path.replaceAll('.rdf_mapper.cache.json', '');

        // Process mappers and context providers from this file
        _processFileMappers(jsonData, modelImportPath, importIndex, mappers,
            providers, namedIriMappers);
      } catch (e, stackTrace) {
        log.warning('Error processing cache file $path: $e', e, stackTrace);
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
      final className = mapperData['className'] as Map?;
      final mapperClassName = mapperData['mapperClassName'] as Map?;

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

    // Extract IRI mapper type and name information
    final type = mapper['type'] as Map<String, dynamic>?; // Code actually
    final name = mapper['name'] as String?;
    final implementationType =
        mapper['implementationType'] as Map<String, dynamic>?; // Code actually
    final isNamed = mapper['isNamed'] as bool? ?? false;
    final isTypeBased = mapper['isTypeBased'] as bool? ?? false;
    final isInstance = mapper['isInstance'] as bool? ?? false;
    final instanceInitializationCode =
        mapper['instanceInitializationCode'] as Map<String, dynamic>?;
    if (type == null) return [];
    Code? code;
    if (isTypeBased && implementationType != null) {
      // instantiate the constructor with empty parameters
      code =
          Code.combine([Code.fromMap(implementationType), Code.literal('()')]);
    } else if (isInstance && instanceInitializationCode != null) {
      code = Code.fromMap(instanceInitializationCode);
    }
    if (code == null && name != null) {
      code = Code.literal(name);
    }
    if (code == null) {
      throw ArgumentError('No valid code found for IRI mapper: $mapper');
    }
    return [
      {
        'type': type,
        'code': code.toMap(),
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

  /// Builds the final template data from processing results
  Map<String, dynamic> _buildFinalTemplateData(
      _ProcessingResult result, bool isTest, String currentPackage) {
    final sortedProviders = _sortProviders(result.providers);
    final sortedNamedIriMappers = _sortIriMappers(result.namedIriMappers);
    final sortedImports = _sortImports(result.imports);
    final sortedModelImports = _sortImports(result.modelImports);
    final knownImports = Map<String, String>.fromIterable(
        [...sortedImports, ...sortedModelImports],
        key: (e) => e['uri'], value: (e) => e['alias'] ?? '');
    final data = _templateRenderer.resolveCodeSnipplets({
      'generatedOn': DateTime.now().toIso8601String(),
      'isTest': isTest,
      'mappers': result.mappers,
      'imports': sortedImports,
      'model_imports': sortedModelImports,
      'providers': sortedProviders,
      'hasProviders': sortedProviders.isNotEmpty,
      'iriMappers': sortedNamedIriMappers,
      'hasIriMappers': sortedNamedIriMappers.isNotEmpty,
    }, importAliases: knownImports);

    // Clean up aliasedImports URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
    _fixupAliasedImports(data, currentPackage);

    return data;
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
  List<Map<String, dynamic>> _sortImports(Set<Map<String, dynamic>> imports) {
    return imports.toList()..sort((a, b) => a['uri']!.compareTo(b['uri']!));
  }

  void _fixupAliasedImports(Map<String, dynamic> data, String currentPackage) {
    if (data['aliasedImports'] is List) {
      final aliasedImports = data['aliasedImports'] as List;
      for (final import in aliasedImports) {
        if (import is Map<String, dynamic> && import['uri'] is String) {
          final uri = import['uri'] as String;
          final cleanedUri = _cleanupImportUri(uri, currentPackage);
          import['uri'] = cleanedUri;
        }
      }
    }
  }

  /// Cleans up import URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
  String _cleanupImportUri(String uri, String currentPackage) {
    // Check for asset:packageName/lib/ prefix
    final libPrefix = 'asset:$currentPackage/lib/';
    if (uri.startsWith(libPrefix)) {
      return 'package:$currentPackage/${uri.substring(libPrefix.length)}';
    }

    // Check for asset:packageName/test/ prefix
    final testPrefix = 'asset:$currentPackage/test/';
    if (uri.startsWith(testPrefix)) {
      return '${uri.substring(testPrefix.length)}';
    }
    // Check for asset:packageName/ prefix
    final assetPrefix = 'asset:$currentPackage/';
    if (uri.startsWith(assetPrefix)) {
      return 'package:$currentPackage/${uri.substring(assetPrefix.length)}';
    }

    // Return the URI unchanged if no prefixes match
    return uri;
  }

  Future<String> build(
    List<(String path, String package, String content)> jsonFiles,
    AssetReader reader, {
    required bool isTest,
    required String outputPath,
    required String currentPackage,
  }) async {
    final templateData = buildTemplateData(
      jsonFiles,
      isTest: isTest,
      outputPath: outputPath,
      currentPackage: currentPackage,
    );
    if (templateData == null) {
      return '';
    }

    return await _templateRenderer.renderInitFileTemplate(templateData, reader);
  }
}
