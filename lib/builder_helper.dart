import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model_builder.dart';
import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/enum_processor.dart';
import 'package:rdf_mapper_generator/src/processors/iri_processor.dart';
import 'package:rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
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
      Iterable<EnumElement2> enumElements,
      AssetReader reader,
      BroaderImports broaderImports,
      {String packageName = "test"}) async {
    final templateData = await buildTemplateData(
        sourcePath, packageName, classElements, enumElements, broaderImports);
    if (templateData != null) {
      // Use the file template approach which handles imports properly
      return await _templateRenderer.renderFileTemplate(
          templateData.mapperFileImportUri, templateData.toMap(), reader);
    }

    return null;
  }

  Future<FileTemplateData?> buildTemplateData(
      String sourcePath,
      String packageName,
      Iterable<ClassElement2> classElements,
      Iterable<EnumElement2> enumElements,
      BroaderImports broaderImports) async {
    final context = ValidationContext();
    // Collect all resource info and element pairs (class or enum)
    List<(MappableClassInfo, Element2?)> resourceInfosWithElements =
        collectResourceInfos(classElements, context, enumElements);
    context.throwIfErrors();

    final fileModel = MapperModelBuilder.buildMapperModels(
        context, packageName, sourcePath, resourceInfosWithElements);
    final mappersById = {for (var m in fileModel.mappers) m.id: m};
    // FIXME: topological sort
    final mappersSortedByDependcy = fileModel.mappers;
    final resolvedMappers = <MapperId, ResolvedMapperModel>{};
    final resolveContext = context.withContext('resolve');
    for (var m in mappersSortedByDependcy) {
      final resolved =
          m.resolve(resolveContext.withContext(m.id.id), resolvedMappers);
      resolvedMappers[resolved.id] = resolved;
    }

    final templateContext = context.withContext('template');
    final templateDatas = resolvedMappers.values
        .map((r) => r.toTemplateData(templateContext.withContext(r.id.id)))
        .toList();

    // Use the file template approach which handles imports properly
    final result = resourceInfosWithElements.isEmpty
        ? null
        : TemplateDataBuilder.buildFileTemplate(
            context.withContext(fileModel.originalSourcePath),
            fileModel.originalSourcePath,
            templateDatas,
            broaderImports,
            fileModel.importAliasByImportUri,
            fileModel.mapperFileImportUri);

    if (context.hasWarnings) {
      for (final warning in context.warnings) {
        _log.warning(warning);
      }
    }
    context.throwIfErrors();
    return result;
  }

  List<(MappableClassInfo, Element2?)> collectResourceInfos(
      Iterable<ClassElement2> classElements,
      ValidationContext context,
      Iterable<EnumElement2> enumElements) {
    // Collect all resource info and element pairs (class or enum)
    final resourceInfosWithElements = <(MappableClassInfo, Element2?)>[];

    for (final classElement in classElements) {
      final resourceInfo = ResourceProcessor.processClass(
            context.withContext(classElement.name3!),
            classElement,
          ) ??
          IriProcessor.processClass(
            context.withContext(classElement.name3!),
            classElement,
          ) ??
          LiteralProcessor.processClass(
            context.withContext(classElement.name3!),
            classElement,
          );

      if (resourceInfo != null) {
        resourceInfosWithElements.add((resourceInfo, classElement));
      }
    }

    // Process enums
    for (final enumElement in enumElements) {
      final enumInfo = EnumProcessor.processEnum(
        context.withContext(enumElement.name3!),
        enumElement,
      );

      if (enumInfo != null) {
        resourceInfosWithElements.add((enumInfo, enumElement));
      }
    }
    return resourceInfosWithElements;
  }
}
