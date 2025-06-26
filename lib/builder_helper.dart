import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/enum_processor.dart';
import 'package:rdf_mapper_generator/src/processors/iri_processor.dart';
import 'package:rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
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
      Iterable<EnumElement2> enumElements,
      BroaderImports broaderImports) async {
    String mapperImportUri = getMapperImportUri(
        packageName, sourcePath.replaceAll('.dart', '.rdf_mapper.g.dart'));
    final context = ValidationContext();
    // Collect all resource info and element pairs (class or enum)
    List<(MappableClassInfo, Element2?)> resourceInfosWithElements =
        collectResourceInfos(classElements, context, enumElements);

    FileTemplateData? result;
    if (resourceInfosWithElements.isNotEmpty) {
      UnresolvedInstantiationCodeData unresolved =
          UnresolvedInstantiationCodeData();
      // Use the file template approach which handles imports properly
      result = TemplateDataBuilder.buildFileTemplate(
          context.withContext(sourcePath),
          sourcePath,
          mapperImportUri,
          resourceInfosWithElements,
          broaderImports,
          unresolved);
      final generatedMappers = result.mappers
          .map((m) => m.mapperData)
          .whereType<GeneratedMapperTemplateData>();

      final constructorParametersByClassName =
          <Code, List<ConstructorParameterData>>{
        for (var mapper in generatedMappers)
          mapper.mapperClassName: mapper.mapperConstructorParameters
      };
      print(
          'Found ${constructorParametersByClassName.length} mappers: ${constructorParametersByClassName.keys.map((m) => m.code).join(', ')}');

      // irimapper template
      for (var mapper in result.mappers) {
        final mapperData = mapper.mapperData;
        if (mapperData is GeneratedMapperTemplateData) {
          for (final constructorParam
              in mapperData.mapperConstructorParameters) {
            if (constructorParam.defaultValue != null &&
                !constructorParam.defaultValue!.isResolved) {
              // Resolve the default value code data for the constructor parameter
              resolve(constructorParam.defaultValue!,
                  constructorParametersByClassName,
                  constContext:
                      constructorParam.isField && !constructorParam.isLate);
            }
          }
        }
        switch (mapperData) {
          case ResourceMapperTemplateData resourceMapper:
            {
              if (resourceMapper.iriStrategy != null &&
                  resourceMapper.iriStrategy!.mapper != null) {
                final mapper = resourceMapper.iriStrategy!.mapper!;
                final code = mapper.instanceInitializationCode;
                if (code != null && !code.isResolved) {
                  // Resolve the instantiation code data for the IRI strategy mapper
                  resolve(code, constructorParametersByClassName,
                      constContext: true);
                }
              }
            }
          case IriMapperTemplateData iriMapper:
            {
              final mapper = iriMapper.iriStrategy.mapper;
              if (mapper != null) {
                final code = mapper.instanceInitializationCode;
                if (code != null && !code.isResolved) {
                  // Resolve the instantiation code data for the IRI strategy mapper
                  resolve(code, constructorParametersByClassName,
                      constContext: true);
                }
              }
            }
          case CustomMapperTemplateData customMapperTemplateData:
            {
              final code = customMapperTemplateData.customMapperInstance;
              if (code != null && !code.isResolved) {
                // Resolve the instantiation code data for the custom mapper
                resolve(code, constructorParametersByClassName,
                    constContext: true);
              }
            }
          default:
            // Other mappers do not have further instantiation code data to resolve
            break;
          // Resolve global resource mappers
        }
      }

      var stillUnresolved =
          unresolved.unresolved.where((r) => !r.isResolved).toList();

      if (stillUnresolved.isNotEmpty) {
        throw StateError(
            'There are still unresolved instantiation code data: ${stillUnresolved.map((r) => r.mapperClassName?.code).join(', ')}');
      }
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

  void resolve(
      ResolvableInstantiationCodeData resolvable,
      Map<Code, List<ConstructorParameterData>>
          constructorParametersByClassName,
      {required bool constContext}) {
    if (resolvable.mapperClassName == null) {
      _log.warning(
          'Unresolved code data without mapper class name: $resolvable');
      return;
    }
    var params = constructorParametersByClassName[resolvable.mapperClassName];
    if (params != null) {
      // Resolve the instantiation code data
      resolvable.resolve(params, constContext: constContext);
    } else {
      _log.warning(
          'Unresolved code data of type ${resolvable.mapperClassName?.code} cannot be properly resolved because we did not find it in the generated mappers. Assuming no-args default constructor.');
      resolvable.resolve([], constContext: constContext);
    }
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

String getMapperImportUri(String packageName, String sourcePath) {
  final mapperImportUri = 'asset:$packageName/${sourcePath}';
  return mapperImportUri;
}
