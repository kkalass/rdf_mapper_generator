import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

Builder rdfMapperSourceBuilder(BuilderOptions options) =>
    RdfMapperSourceBuilder();

/// Second phase builder that generates source files from cached template data.
/// This builder runs after the cache builder and generates the final source files.
class RdfMapperSourceBuilder implements Builder {
  static final _templateRenderer = TemplateRenderer();

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only process .cache.json files
    if (!buildStep.inputId.path.endsWith('.rdf_mapper.cache.json')) {
      return;
    }

    try {
      // Read and parse the cache file
      final jsonString = await buildStep.readAsString(buildStep.inputId);
      final jsonData = jsonDecode(jsonString);
      String mapperImportUri = getMapperImportUri(buildStep.inputId.package,
          buildStep.inputId.path.replaceAll('.cache.json', '.g.dart'));

      // Render the template
      final generatedCode = await _templateRenderer.renderFileTemplate(
        mapperImportUri,
        jsonData,
        buildStep,
      );

      // Generate the output file path by replacing the cache extension
      final outputPath = buildStep.inputId.path
          .replaceAll('.rdf_mapper.cache.json', '.rdf_mapper.g.dart');
      final outputId = AssetId(
        buildStep.inputId.package,
        outputPath,
      );

      await buildStep.writeAsString(outputId, generatedCode);
      log.fine('Generated RDF mapper source for ${buildStep.inputId.path}');
    } catch (e, stackTrace) {
      log.severe(
        'Error processing cache file ${buildStep.inputId.path}: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => 
      const {'.rdf_mapper.cache.json': ['.rdf_mapper.g.dart']};
}
