import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/template_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:build/build.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:logging/logging.dart';

final _log = Logger('BuilderHelper');

class BuilderHelper {
  static final _templateRenderer = TemplateRenderer();

  Future<String?> build(
      String sourcePath,
      Iterable<ClassElement2> classElements,
      LibsByClassName libsByClassName,
      AssetReader reader) async {
    final templateData =
        await buildTemplateData(sourcePath, classElements, libsByClassName);

    if (templateData != null) {
      // Use the file template approach which handles imports properly
      return await _templateRenderer.renderFileTemplate(templateData, reader);
    }

    return null;
  }

  Future<Map<String, dynamic>?> buildTemplateData(
      String sourcePath,
      Iterable<ClassElement2> classElements,
      LibsByClassName libsByClassName) async {
    final context = ValidationContext();
    // Collect all resource info and class elements
    final resourceInfosWithElements = <(MappableClassInfo, ClassElement2)>[];

    for (final classElement in classElements) {
      final resourceInfo = GlobalResourceProcessor.processClass(
        context.withContext(classElement.name3!),
        classElement,
        libsByClassName: libsByClassName,
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
        resourceInfosWithElements,
      );
    }

    if (context.hasWarnings) {
      for (final warning in context.warnings) {
        _log.warning(warning);
      }
    }
    context.throwIfErrors();
    return result?.toMap();
  }
}
