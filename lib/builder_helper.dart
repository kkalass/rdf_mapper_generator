import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/template_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('BuilderHelper');

class BuilderHelper {
  static final _templateRenderer = TemplateRenderer();

  Future<String?> build(
      String sourcePath,
      Iterable<ClassElement2> classElements,
      AssetReader reader,
      BroaderImports broaderImports,
      {String packageName = "test"}) async {
    final templateData = await buildTemplateData(
        sourcePath, packageName, classElements, broaderImports);
    String mapperImportUri = getMapperImportUri(
        packageName, sourcePath.replaceAll('.dart', '.rdf_mapper.g.dart'));
    if (templateData != null) {
      // Use the file template approach which handles imports properly
      return await _templateRenderer.renderFileTemplate(
          mapperImportUri, templateData, reader);
    }

    return null;
  }

  Future<Map<String, dynamic>?> buildTemplateData(
      String sourcePath,
      String packageName,
      Iterable<ClassElement2> classElements,
      BroaderImports broaderImports) async {
    String mapperImportUri = getMapperImportUri(
        packageName, sourcePath.replaceAll('.dart', '.rdf_mapper.g.dart'));
    final context = ValidationContext();
    // Collect all resource info and class elements
    final resourceInfosWithElements = <(MappableClassInfo, ClassElement2)>[];

    for (final classElement in classElements) {
      final resourceInfo = GlobalResourceProcessor.processClass(
        context.withContext(classElement.name3!),
        classElement,
      );

      if (resourceInfo != null) {
        resourceInfosWithElements.add((resourceInfo, classElement));
      }
    }

    FileTemplateData? result;
    if (resourceInfosWithElements.isNotEmpty) {
      // Use the file template approach which handles imports properly
      result = TemplateDataBuilder.buildFileTemplate(
          context.withContext(sourcePath),
          sourcePath,
          mapperImportUri,
          resourceInfosWithElements,
          broaderImports);
    }

    if (context.hasWarnings) {
      for (final warning in context.warnings) {
        _log.warning(warning);
      }
    }
    context.throwIfErrors();

    var map = result?.toMap();

    return map;
  }
}

String getMapperImportUri(String packageName, String sourcePath) {
  final mapperImportUri = 'asset:$packageName/${sourcePath}';
  return mapperImportUri;
}
