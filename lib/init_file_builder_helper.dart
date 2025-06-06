import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

class InitFileBuilderHelper {
  static final _templateRenderer = TemplateRenderer();
  final Logger log = Logger('InitFileBuilderHelper');

  InitFileBuilderHelper();

  Map<String, dynamic>? buildTemplateData(
      List<(String path, String package, String content)> jsonFiles,
      {required bool isTest,
      required String outputPath}) {
    try {
      // Process each cache file to extract mapper information
      final mappers = <Map<String, dynamic>>[];
      final imports = <Map<String, String>>{};
      final modelImports = <Map<String, String>>{};
      final providers = <String, Map<String, dynamic>>{};
      final sortedJsonFiles = List.from(jsonFiles)
        ..sort((a, b) {
          final (aPath, aPackage, _) = a;
          final (bPath, bPackage, _) = b;
          final cmp = aPackage.compareTo(bPackage);
          if (cmp != 0) return cmp;
          return aPath.compareTo(bPath);
        });

      int importIndex = -1;
      for (final file in sortedJsonFiles) {
        importIndex++;
        final (path, package, content) = file;
        try {
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          final modelImportPath = path.replaceAll('.rdf_mapper.cache.json', '');
          // Extract mappers from the cache file
          final mappersData = jsonData['mappers'] as List? ?? [];
          for (final mapperData in mappersData.cast<Map<String, dynamic>>()) {
            final className = mapperData['className'] as String?;
            final mapperClassName = mapperData['mapperClassName'] as String?;

            // Collect context providers if they exist
            final contextProviders = (mapperData['contextProviders'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
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

            if (className != null && mapperClassName != null) {
              final contextProviders = (mapperData['contextProviders'] as List?)
                      ?.cast<Map<String, dynamic>>() ??
                  [];
              final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;
              
              // Only add the mapper if registerGlobally is true or not set (defaults to true)
              if (registerGlobally) {
                mappers.add({
                  'name': mapperClassName,
                  'type': className,
                  '_importPath': modelImportPath,
                  '_importIndex': importIndex,
                  'hasContextProviders': contextProviders.isNotEmpty,
                  'contextProviders': contextProviders,
                });
              }
            }
          }

          // Add import for the generated mapper file and model file

          if (isTest) {
            // For test files, use relative imports within the test directory
            var relativePath =
                p.relative(modelImportPath, from: p.dirname(outputPath));
            if (relativePath == '.') {
              // If the file is in the same directory, just use the filename
              relativePath = p.basename(modelImportPath);
            }
            imports.add({
              'value': '$relativePath.rdf_mapper.g.dart',
              'index': importIndex.toString()
            });
            modelImports.add({
              'value': '$relativePath.dart',
              'index': importIndex.toString()
            });
          } else if (!modelImportPath.startsWith('package:')) {
            // For non-test files, convert relative path to package import
            final fullImportPath =
                'package:$package/${p.relative(modelImportPath, from: 'lib')}';
            imports.add({
              'value': '$fullImportPath.rdf_mapper.g.dart',
              'index': importIndex.toString()
            });
            modelImports.add({
              'value': '$fullImportPath.dart',
              'index': importIndex.toString()
            });
          } else {
            // For absolute package imports
            imports.add({
              'value': '$modelImportPath.rdf_mapper.g.dart',
              'index': importIndex.toString()
            });
            modelImports.add({
              'value': '$modelImportPath.dart',
              'index': importIndex.toString()
            });
          }
        } catch (e) {
          log.warning('Error processing cache file $path: $e');
        }
      }

      // Convert providers map to list and sort by parameter name for consistent ordering
      final sortedProviders = providers.values.toList()
        ..sort((a, b) => (a['parameterName'] as String)
            .compareTo(b['parameterName'] as String));
      // Sort imports and model imports by value for consistent ordering
      final sortedImports = imports.toList()
        ..sort((a, b) => a['value']!.compareTo(b['value']!));
      final sortedModelImports = modelImports.toList()
        ..sort((a, b) => a['value']!.compareTo(b['value']!));

      return {
        'generatedOn': DateTime.now().toIso8601String(),
        'isTest': isTest,
        'mappers': mappers,
        'imports': sortedImports,
        'model_imports': sortedModelImports,
        'providers': sortedProviders,
        'hasProviders': sortedProviders.isNotEmpty,
      };
    } catch (e, stackTrace) {
      log.severe('Error building template data: $e', e, stackTrace);
      rethrow;
    }
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
    print(JsonEncoder.withIndent('  ').convert(templateData));
    return await _templateRenderer.renderInitFileTemplate(templateData, reader);
  }
}
