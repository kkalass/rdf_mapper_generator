import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

class _InitFileTemplateData {
  final String generatedOn;
  final bool isTest;
  final List<_Mapper> mappers;
  final List<_Provider> providers;
  final List<_CustomMapper> namedCustomMappers;

  _InitFileTemplateData(
      {required this.generatedOn,
      required this.isTest,
      required this.mappers,
      required this.providers,
      required this.namedCustomMappers});

  Map<String, dynamic> toMap() {
    return {
      'generatedOn': generatedOn,
      'isTest': isTest,
      'mappers': mappers.map((m) => m.toMap()).toList(),
      'providers': providers.map((p) => p.toMap()).toList(),
      'hasProviders': providers.isNotEmpty,
      'namedCustomMappers': namedCustomMappers.map((i) => i.toMap()).toList(),
      'hasNamedCustomMappers': namedCustomMappers.isNotEmpty,
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
  final Code type;
  final Code code;

  _Mapper({
    required this.type,
    required this.code,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toMap(),
      'code': code.toMap(),
    };
  }
}

class _CustomMapper {
  final Code type;
  final Code code;
  final String parameterName;
  final bool isNamed;
  final bool isTypeBased;
  final bool isInstance;
  final String? name;
  _CustomMapper({
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

typedef _InitFileContributions = (
  Iterable<_Mapper>,
  Map<String, _Provider>,
  Map<String, _CustomMapper>
);
const _InitFileContributions noInitFileContributions = (
  const <_Mapper>[],
  const <String, _Provider>{},
  const <String, _CustomMapper>{}
);

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
    final contributions = sortedJsonFiles.map((file) {
      final (path, package, content) = file;

      try {
        var jsonData = jsonDecode(content) as Map<String, dynamic>;

        // Process mappers and context providers from this file
        return _processFileMappers(jsonData);
      } catch (e, stackTrace) {
        log.warning('Error processing cache file $path: $e', e, stackTrace);
        return noInitFileContributions;
      }
    });

    final (mappers, providers, namedCustomMappers) =
        mergeInitFileContributions(contributions);
    final sortedProviders = _sortProviders(providers);
    final sortedNamedCustomMappers = _sortCustomMappers(namedCustomMappers);
    return _InitFileTemplateData(
      generatedOn: DateTime.now().toIso8601String(),
      isTest: isTest,
      mappers: mappers.toList(growable: false),
      providers: sortedProviders,
      namedCustomMappers: sortedNamedCustomMappers,
    );
  }

  /// Processes mappers and context providers from a single JSON file
  _InitFileContributions _processFileMappers(Map<String, dynamic> jsonData) {
    final mappersData =
        (jsonData['mappers'] as List? ?? []).cast<Map<String, dynamic>>();
    final all = mappersData.map<_InitFileContributions>(
        (mapperData) => switch (mapperData['__type__'] as String?) {
              'ResourceMapperTemplateData' => collectResourceMapper(mapperData),
              'CustomMapperTemplateData' => collectCustomMapper(mapperData),
              'IriMapperTemplateData' => collectIriMapper(mapperData),
              'LiteralMapperTemplateData' => collectLiteralMapper(mapperData),
              _ => () {
                  log.warning('Unknown mapper type: ${mapperData['__type__']}');
                  return noInitFileContributions;
                }()
            });
    return mergeInitFileContributions(all);
  }

  _InitFileContributions mergeInitFileContributions(
      Iterable<_InitFileContributions> all) {
    return (
      all.expand((c) => c.$1).toList(),
      all.fold<Map<String, _Provider>>({}, (acc, c) => {...acc, ...c.$2}),
      all.fold<Map<String, _CustomMapper>>({}, (acc, c) => {...acc, ...c.$3})
    );
  }

  _InitFileContributions collectResourceMapper(
      Map<String, dynamic> mapperData) {
    final className = extractNullableCodeProperty(mapperData, 'className');
    final mapperClassName =
        extractNullableCodeProperty(mapperData, 'mapperClassName');

    if (className == null || mapperClassName == null) {
      return noInitFileContributions;
    }

    // Extract context providers for this mapper
    final contextProviders = _extractContextProviders(mapperData);
    final providersByName =
        _indexProviders(contextProviders.map((e) => e.value));

    // Extract IRI mappers for this mapper
    final customIriMappers = _extractCustomIriMappers(mapperData);
    final customMappersByName = _indexNamedIriMappers(customIriMappers);

    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;
    final code = _buildCodeInstantiateMapperWithIriMapper(
        mapperClassName, contextProviders, customIriMappers);
    if (registerGlobally) {
      return (
        [
          _Mapper(
            code: code,
            type: className,
          )
        ],
        providersByName,
        customMappersByName
      );
    }
    return (const [], providersByName, customMappersByName);
  }

  Code _buildCodeInstantiateMapperWithIriMapper(
      Code mapperClassName,
      List<_MustacheListEntry<_ContextProvider>> contextProviders,
      List<_CustomMapper> customIriMappers) {
    var params = [
      ..._contextProvidersToParams(contextProviders),
      ...customIriMappers.map((i) => (i.parameterName, i.code)),
    ];
    return _buildCodeInstantiateMapper(mapperClassName, params);
  }

  Iterable<(String, Code)> _contextProvidersToParams(
      List<_MustacheListEntry<_ContextProvider>> contextProviders) {
    return contextProviders.map((cp) => (
          cp.value.parameterName,
          Code.literal(cp.value.parameterName),
        ));
  }

  Code _buildCodeInstantiateMapper(
      Code mapperClassName, List<(String paramName, Code paramValue)> params) {
    return Code.combine([
      mapperClassName,
      Code.literal('('),
      ...params.map((cp) => Code.combine(
          [Code.literal(cp.$1), Code.literal(':'), cp.$2, Code.literal(', ')])),
      Code.literal(')')
    ]);
  }

  _InitFileContributions collectIriMapper(Map<String, dynamic> mapperData) {
    final className = extractNullableCodeProperty(mapperData, 'className');
    final mapperClassName =
        extractNullableCodeProperty(mapperData, 'mapperClassName');

    if (className == null || mapperClassName == null) {
      return noInitFileContributions;
    }

    // Extract context providers for this mapper
    final contextProviders = _extractContextProviders(mapperData);
    final providersByName =
        _indexProviders(contextProviders.map((e) => e.value));

    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;

    if (registerGlobally) {
      final code = _buildCodeInstantiateMapper(mapperClassName,
          _contextProvidersToParams(contextProviders).toList());
      return (
        [
          _Mapper(
            code: code,
            type: className,
          )
        ],
        providersByName,
        {}
      );
    }
    return (const [], providersByName, {});
  }

  _InitFileContributions collectLiteralMapper(Map<String, dynamic> mapperData) {
    final className = extractNullableCodeProperty(mapperData, 'className');
    final mapperClassName =
        extractNullableCodeProperty(mapperData, 'mapperClassName');

    if (className == null || mapperClassName == null) {
      return noInitFileContributions;
    }

    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;

    if (registerGlobally) {
      final code = _buildCodeInstantiateMapper(mapperClassName, const []);
      return (
        [
          _Mapper(
            code: code,
            type: className,
          )
        ],
        const {},
        const {}
      );
    }
    return noInitFileContributions;
  }

  _InitFileContributions collectCustomMapper(Map<String, dynamic> mapperData) {
    final className = extractCodeProperty(mapperData, 'className');
    final mapperInterfaceType =
        extractCodeProperty(mapperData, 'mapperInterfaceType');
    final customMapperType =
        extractNullableCodeProperty(mapperData, 'customMapperType');
    final customMapperInstance =
        extractNullableCodeProperty(mapperData, 'customMapperInstance');
    final customMapperName = mapperData['customMapperName'] as String?;
    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;

    if (registerGlobally) {
      final code = customMapperCode(
          customMapperType, customMapperInstance, customMapperName, mapperData);
      final customMapper = _CustomMapper(
        type: mapperInterfaceType,
        code: code,
        name: customMapperName,
        parameterName: customMapperName ?? 'customMapper',
        isNamed: customMapperName != null,
        isTypeBased: customMapperType != null,
        isInstance: customMapperInstance != null,
      );
      return (
        [
          _Mapper(
            type: className,
            code: code,
          )
        ],
        {},
        {
          if (customMapper.isNamed && customMapper.name != null)
            customMapper.name!: customMapper
        }
      );
    }
    return noInitFileContributions;
  }

  Code? extractNullableCodeProperty(
          Map<String, dynamic> mapperData, String propertyName) =>
      mapperData[propertyName] != null
          ? extractCodeProperty(mapperData, propertyName)
          : null;

  Code extractCodeProperty(
          Map<String, dynamic> mapperData, String propertyName) =>
      Code.fromMap(mapperData[propertyName] as Map<String, dynamic>);

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
  Map<String, _Provider> _indexProviders(
          Iterable<_ContextProvider> contextProviders) =>
      {
        for (final provider in contextProviders)
          provider.variableName: _Provider(
            variableName: provider.variableName,
            parameterName: provider.parameterName,
            placeholder: provider.placeholder,
            privateFieldName: provider.privateFieldName,
          ),
      };

  /// Extracts IRI mappers from mapper data
  List<_CustomMapper> _extractCustomIriMappers(
      Map<String, dynamic> mapperData) {
    final iriStrategy = mapperData['iriStrategy'] as Map<String, dynamic>?;
    if (iriStrategy == null) return [];

    final mapper = iriStrategy['mapper'] as Map<String, dynamic>?;
    if (mapper == null) return [];

    // Extract IRI mapper type and name information
    final type = extractNullableCodeProperty(mapper, 'type');
    final name = mapper['name'] as String?;
    final implementationType =
        extractNullableCodeProperty(mapper, 'implementationType');

    final isNamed = mapper['isNamed'] as bool? ?? false;
    final isTypeBased = mapper['isTypeBased'] as bool? ?? false;
    final isInstance = mapper['isInstance'] as bool? ?? false;
    final instanceInitializationCode =
        extractNullableCodeProperty(mapper, 'instanceInitializationCode');
    if (type == null) return [];
    final code = customMapperCode(
        implementationType, instanceInitializationCode, name, mapper);
    return [
      _CustomMapper(
          type: type,
          code: code,
          parameterName: 'iriMapper',
          isNamed: isNamed,
          isTypeBased: isTypeBased,
          isInstance: isInstance,
          name: name),
    ];
  }

  Code customMapperCode(
      Code? implementationType,
      Code? instanceInitializationCode,
      String? name,
      Map<String, dynamic> mapperData) {
    Code? code;
    if (implementationType != null) {
      // instantiate the constructor with empty parameters
      code = Code.combine([implementationType, Code.literal('()')]);
    } else if (instanceInitializationCode != null) {
      code = instanceInitializationCode;
    }
    if (code == null && name != null) {
      code = Code.literal(name);
    }
    if (code == null) {
      throw ArgumentError('No valid code found for IRI mapper $mapperData');
    }
    return code;
  }

  /// Collects IRI mappers into the iriMappers map
  Map<String, _CustomMapper> _indexNamedIriMappers(
          List<_CustomMapper> iriMapperInfos) =>
      {
        for (final info in iriMapperInfos)
          if (info.isNamed && info.name != null && info.name!.isNotEmpty)
            info.name!: info
      };

  /// Builds the final template data from processing results
  Map<String, dynamic> _buildFinalTemplateData(
    _InitFileTemplateData result,
    String currentPackage,
  ) {
    final rawData = result.toMap();
    final data = _templateRenderer.resolveCodeSnipplets(rawData,
        defaultImports: [importRdfMapper, importDartCore]);

    // Clean up aliasedImports URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
    _fixupAliasedImports(data, currentPackage);

    return data;
  }

  /// Sorts providers by parameter name for consistent ordering
  List<_Provider> _sortProviders(Map<String, _Provider> providers) {
    return providers.values.toList()
      ..sort((a, b) => (a.parameterName).compareTo(b.parameterName));
  }

  /// Sorts IRI mappers by parameter name for consistent ordering
  List<_CustomMapper> _sortCustomMappers(
      Map<String, _CustomMapper> iriMappers) {
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
