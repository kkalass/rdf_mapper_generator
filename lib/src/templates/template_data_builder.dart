import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/resource_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Builds template data from processed resource information.
class TemplateDataBuilder {
  /// Builds file template data for multiple global resource mappers.
  static FileTemplateData buildFileTemplate(
    ValidationContext context,
    String sourcePath,
    String mapperImportUri,
    List<(MappableClassInfo, ClassElement2)> resourceInfosWithElements,
    BroaderImports broaderImports,
  ) {
    final header = FileHeaderData(
      sourcePath: sourcePath,
      generatedOn: DateTime.now().toIso8601String(),
    );

    // Collect all imports from all mappers and deduplicate
    final allImports = <String>{};
    final mapperDatas = <MapperData>[];

    for (final (resourceInfo, _) in resourceInfosWithElements) {
      final MappableClassMapperTemplateData mapperData = switch (resourceInfo) {
        ResourceInfo _ => resourceInfo.annotation.mapper != null
            ? ResourceDataBuilder.buildResourceMapperCustom(resourceInfo)
            : // Use custom mapper if specified
            ResourceDataBuilder.buildResourceMapper(
                resourceInfo, mapperImportUri),
      };

      // Add imports from this mapper
      allImports.addAll(mapperData.imports.map((i) => i.import));

      mapperDatas.add(MapperData(mapperData));
    }

    final imports = allImports.map(ImportData.new).toList();

    return FileTemplateData(
      header: header,
      imports: imports,
      mappers: mapperDatas,
      broaderImports: broaderImports,
    );
  }
}
