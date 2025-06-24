import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/data_builder.dart';
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
    final mapperDatas = resourceInfosWithElements
        .map((e) => e.$1)
        .expand((resourceInfo) => switch (resourceInfo) {
              ResourceInfo _ => resourceInfo.annotation.mapper != null
                  ? DataBuilder.buildCustomMapper(
                      context, resourceInfo.className, resourceInfo.annotation)
                  : // generate custom mapper if specified
                  DataBuilder.buildResourceMapper(
                      context, resourceInfo, mapperImportUri),
              IriInfo _ => resourceInfo.annotation.mapper != null
                  ? DataBuilder.buildCustomMapper(
                      context, resourceInfo.className, resourceInfo.annotation)
                  : DataBuilder.buildIriMapper(
                      context, resourceInfo, mapperImportUri),
              LiteralInfo _ => resourceInfo.annotation.mapper != null
                  ? DataBuilder.buildCustomMapper(
                      context, resourceInfo.className, resourceInfo.annotation)
                  : DataBuilder.buildLiteralMapper(
                      context, resourceInfo, mapperImportUri),
            })
        .map(MapperData.new)
        .toList();

    final allLibraryImports = resourceInfosWithElements
        .expand((e) => e.$2.library2.fragments)
        .expand((f) => f.libraryImports2);
    final Map<String, String> originalImports = {
      for (final import in allLibraryImports)
        if (import.importedLibrary2 != null)
          import.importedLibrary2!.identifier: import.prefix2?.name2 ?? '',
    };
    return FileTemplateData(
      header: header,
      mappers: mapperDatas,
      broaderImports: broaderImports,
      originalImports: originalImports,
    );
  }
}
