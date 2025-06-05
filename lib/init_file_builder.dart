import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:rdf_mapper_generator/init_file_builder_helper.dart';

/// Builder that generates the init_rdf_mapper.g.dart file with all mappers registered.
Builder rdfInitFileBuilder(BuilderOptions options) => RdfInitFileBuilder();

class RdfInitFileBuilder implements Builder {
  static final _builderHelper = InitFileBuilderHelper();

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only process pubspec.yaml
    if (!buildStep.inputId.path.endsWith('pubspec.yaml')) {
      return;
    }

    try {
      // Find all generated cache files
      final cacheFiles = await buildStep
          .findAssets(
            Glob('lib/**.rdf_mapper.cache.json'),
          )
          .toList();

      if (cacheFiles.isEmpty) {
        // No cache files found, skip generation
        return;
      }

      // Process each cache file to extract mapper information

      final jsonFiles = await Future.wait(cacheFiles
          .map((file) async =>
              (file.path, file.package, await buildStep.readAsString(file)))
          .toList());
      final generatedCode = await _builderHelper.build(jsonFiles, buildStep);
      if (generatedCode == null) {
        return;
      }

      // Write the output file
      final outputId = AssetId(
        buildStep.inputId.package,
        'lib/init_rdf_mapper.g.dart',
      );

      await buildStep.writeAsString(outputId, generatedCode);
      log.fine('Generated init_rdf_mapper.g.dart ');
    } catch (e, stackTrace) {
      log.severe(
        'Error generating init_rdf_mapper.g.dart: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'pubspec.yaml': ['lib/init_rdf_mapper.g.dart'],
      };
}
