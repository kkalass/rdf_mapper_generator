import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';
import 'package:rdf_mapper_generator/src/templates/template_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:build/build.dart';

class BuilderHelper {
  static final _templateRenderer = TemplateRenderer();

  Future<String?> build(ClassElement2 classElement,
      LibsByClassName libsByClassName, AssetReader reader) async {
    final resourceInfo = GlobalResourceProcessor.processClass(
      classElement,
      libsByClassName: libsByClassName,
    );

    if (resourceInfo != null) {
      final templateData =
          TemplateDataBuilder.buildGlobalResourceMapper(resourceInfo);
      final mapperCode = await _templateRenderer.renderGlobalResourceMapper(
          templateData, reader);
      return mapperCode;
    }
    return null;
  }
}
