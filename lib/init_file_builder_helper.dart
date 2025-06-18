import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

class _InitFileTemplateData {
  final String generatedOn;
  final bool isTest;
  final List<_Mapper> mappers;
  final List<_Provider> providers;
  final List<_IriMapper> iriMappers;

  _InitFileTemplateData(
      {required this.generatedOn,
      required this.isTest,
      required this.mappers,
      required this.providers,
      required this.iriMappers});

  Map<String, dynamic> toMap() {
    return {
      'generatedOn': generatedOn,
      'isTest': isTest,
      'mappers': mappers.map((m) => m.toMap()).toList(),
      'providers': providers.map((p) => p.toMap()).toList(),
      'hasProviders': providers.isNotEmpty,
      'iriMappers': iriMappers.map((i) => i.toMap()).toList(),
      'hasIriMappers': iriMappers.isNotEmpty,
    };
  }
}

class _MustacheListEntry<T> {
  final Map<String, dynamic> Function(T value) _valueToMap;
  final T value;
  final bool last;

  _MustacheListEntry(this._valueToMap, this.value, {this.last = false});

  Map<String, dynamic> toMap() {
    return {
      'value': _valueToMap(value),
      'last': last,
    };
  }
}

class _ContextProvider {
  /// The name of the context variable
  final String variableName;

  /// The name of the private field that stores the provider
  final String privateFieldName;

  /// The name of the constructor parameter
  final String parameterName;

  /// The placeholder pattern to replace in IRI templates (e.g., '{baseUri}')
  final String placeholder;

  const _ContextProvider({
    required this.variableName,
    required this.privateFieldName,
    required this.parameterName,
    required this.placeholder,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'privateFieldName': privateFieldName,
        'parameterName': parameterName,
        'placeholder': placeholder,
      };
}

class _Mapper {
  final Code name;
  final Code type;
  final String modelImportPath;
  final int importIndex;
  final List<_MustacheListEntry<_ContextProvider>> contextProviders;
  final List<_IriMapper> iriMapperInfo;

  _Mapper(
      {required this.name,
      required this.type,
      required this.modelImportPath,
      required this.importIndex,
      required this.contextProviders,
      required this.iriMapperInfo});

  Map<String, dynamic> toMap() {
    return {
      'name': name.toMap(),
      'type': type.toMap(),
      '_importPath': modelImportPath,
      '_importIndex': importIndex,
      'hasContextProviders': contextProviders.isNotEmpty,
      'contextProviders': contextProviders.map((cp) => cp.toMap()).toList(),
      'hasIriMappers': iriMapperInfo.isNotEmpty,
      'iriMappers': iriMapperInfo.map((i) => i.toMap()).toList(),
    };
  }
}

class _IriMapper {
  final Code type;
  final Code code;
  final String parameterName;
  final bool isNamed;
  final bool isTypeBased;
  final bool isInstance;
  final String? name;
  _IriMapper({
    required this.type,
    required this.code,
    required this.parameterName,
    required this.isNamed,
    required this.isTypeBased,
    required this.isInstance,
    required this.name,
  });
  Map<String, dynamic> toMap() {
    return {
      'type': type.toMap(),
      'code': code.toMap(),
      'parameterName': parameterName,
      'isNamed': isNamed,
      'isTypeBased': isTypeBased,
      'isInstance': isInstance,
      'name': name,
    };
  }
}

class _Provider {
  final String variableName;
  final String parameterName;
  final String placeholder;
  final String privateFieldName;
  _Provider({
    required this.variableName,
    required this.parameterName,
    required this.placeholder,
    required this.privateFieldName,
  });

  Map<String, dynamic> toMap() {
    return {
      'variableName': variableName,
      'parameterName': parameterName,
      'placeholder': placeholder,
      'privateFieldName': privateFieldName,
      'type': 'String', // Default type, can be extended if needed
    };
  }
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
      final templateData =
          _processJsonFiles(sortedJsonFiles, isTest, outputPath);

      return _buildFinalTemplateData(templateData, currentPackage);
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
  _InitFileTemplateData _processJsonFiles(
      List<(String path, String package, String content)> sortedJsonFiles,
      bool isTest,
      String outputPath) {
    final mappers = <_Mapper>[];
    final providers = <String, _Provider>{};
    final namedIriMappers = <String, _IriMapper>{};

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
    final sortedProviders = _sortProviders(providers);
    final sortedNamedIriMappers = _sortIriMappers(namedIriMappers);
    return _InitFileTemplateData(
      generatedOn: DateTime.now().toIso8601String(),
      isTest: isTest,
      mappers: mappers,
      providers: sortedProviders,
      iriMappers: sortedNamedIriMappers,
    );
  }

  /// Processes mappers and context providers from a single JSON file
  void _processFileMappers(
      Map<String, dynamic> jsonData,
      String modelImportPath,
      int importIndex,
      List<_Mapper> mappers,
      Map<String, _Provider> providers,
      Map<String, _IriMapper> namedIriMappers) {
    final mappersData = jsonData['mappers'] as List? ?? [];

    for (final mapperData in mappersData.cast<Map<String, dynamic>>()) {
      final mapperType = mapperData['__type__'] as String?;
      // ResourceMapperTemplateData
      // CustomMapperTemplateData
      final className = mapperData['className'] as Map<String, dynamic>?;
      final mapperClassName =
          mapperData['mapperClassName'] as Map<String, dynamic>?;

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
        mappers.add(_Mapper(
            name: Code.fromMap(mapperClassName),
            type: Code.fromMap(className),
            modelImportPath: modelImportPath,
            importIndex: importIndex,
            contextProviders: contextProviders,
            iriMapperInfo: iriMapperInfo));
      }
    }
  }

  /// Extracts context providers from mapper data
  List<_MustacheListEntry<_ContextProvider>> _extractContextProviders(
      Map<String, dynamic> mapperData) {
    var data = (mapperData['contextProviders'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    return data.map((d) {
      final value = d['value'] as Map<String, dynamic>;
      final contextProvider = _ContextProvider(
          variableName: value['variableName'] as String,
          privateFieldName: value['privateFieldName'] as String,
          parameterName: value['parameterName'] as String,
          placeholder: value['placeholder'] as String);
      final last = d['last'] as bool;
      return _MustacheListEntry<_ContextProvider>(
          (ct) => ct.toMap(), contextProvider,
          last: last);
    }).toList();
  }

  /// Collects context providers into the providers map
  void _collectContextProviders(
      List<_MustacheListEntry<_ContextProvider>> contextProviders,
      Map<String, _Provider> providers) {
    for (final ct in contextProviders) {
      final provider = ct.value;
      providers[provider.variableName] = _Provider(
        variableName: provider.variableName,
        parameterName: provider.parameterName,
        placeholder: provider.placeholder,
        privateFieldName: provider.privateFieldName,
      );
    }
  }

  /// Extracts IRI mappers from mapper data
  List<_IriMapper> _extractIriMappers(Map<String, dynamic> mapperData) {
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
      _IriMapper(
          type: Code.fromMap(type),
          code: code,
          parameterName: 'iriMapper',
          isNamed: isNamed,
          isTypeBased: isTypeBased,
          isInstance: isInstance,
          name: name),
    ];
  }

  /// Collects IRI mappers into the iriMappers map
  void _collectIriMappers(
      List<_IriMapper> iriMapperInfos, Map<String, _IriMapper> iriMappers) {
    for (final info in iriMapperInfos) {
      final name = info.name;
      if (name != null && name.isNotEmpty) {
        iriMappers[name] = info;
      }
    }
  }

  /// Builds the final template data from processing results
  Map<String, dynamic> _buildFinalTemplateData(
    _InitFileTemplateData result,
    String currentPackage,
  ) {
    final rawData = result.toMap();
    final data = _templateRenderer.resolveCodeSnipplets(
      rawData,
    );

    // Clean up aliasedImports URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
    _fixupAliasedImports(data, currentPackage);

    return data;
  }

  /// Sorts providers by parameter name for consistent ordering
  List<_Provider> _sortProviders(Map<String, _Provider> providers) {
    return providers.values.toList()
      ..sort((a, b) => (a.parameterName!).compareTo(b.parameterName!));
  }

  /// Sorts IRI mappers by parameter name for consistent ordering
  List<_IriMapper> _sortIriMappers(Map<String, _IriMapper> iriMappers) {
    return iriMappers.values.toList()
      ..sort((a, b) => (a.name!).compareTo(b.name!));
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
