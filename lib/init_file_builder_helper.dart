import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

class InitFileBuilderHelper {
  static final _templateRenderer = TemplateRenderer();

  Map<String, dynamic>? buildTemplateData(
      List<(String path, String package, String content)> jsonFiles,
      {required bool isTest}) {
    try {
      // Process each cache file to extract mapper information
      final mappers = <Map<String, String>>[];
      final imports = <String>{};

      for (final file in jsonFiles) {
        final (path, package, content) = file;
        try {
          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          // Extract mappers from the cache file
          final mappersData = jsonData['mappers'] as List? ?? [];
          for (final mapperData in mappersData.cast<Map<String, dynamic>>()) {
            final className = mapperData['className'] as String?;
            final mapperClassName = mapperData['mapperClassName'] as String?;

            if (className != null && mapperClassName != null) {
              mappers.add({
                'name': mapperClassName,
                'type': className,
              });
            }
          }

          // Add import for the generated mapper file
          final importPath =
              path.replaceAll('.rdf_mapper.cache.json', '.rdf_mapper.g.dart');

          if (!importPath.startsWith('package:')) {
            // Convert relative path to package import
            final packageName = package;
            imports.add(
                'package:$packageName/${importPath.replaceFirst('lib/', '')}');
          } else {
            imports.add(importPath);
          }
        } catch (e) {
          log.warning('Error processing cache file ${path}: $e');
        }
      }

      if (mappers.isEmpty) {
        // No mappers found in any files
        return null;
      }

      // Sort for deterministic output
      mappers.sort((a, b) => a['name']!.compareTo(b['name']!));

      // Prepare template data
      return {
        'isTest': isTest,
        'generatedOn': DateTime.now().toIso8601String(),
        'imports': imports.toList()..sort(),
        'mappers': mappers,
      };
    } catch (e, stackTrace) {
      log.severe(
        'Error generating init_rdf_mapper.g.dart: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> build(
    List<(String path, String package, String content)> jsonFiles,
    AssetReader reader, {
    required bool isTest,
  }) async {
    final data = buildTemplateData(jsonFiles, isTest: isTest);
    if (data == null) {
      return null;
    }
    return _templateRenderer.renderInitFileTemplate(data, reader);
  }
}
