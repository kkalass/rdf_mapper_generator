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
    List<(MappableClassInfo, Element2?)> resourceInfosWithElements,
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
              IriInfo iriInfo => iriInfo.annotation.mapper != null
                  ? DataBuilder.buildCustomMapper(
                      context, iriInfo.className, iriInfo.annotation)
                  : iriInfo.enumValues.isNotEmpty
                      ? DataBuilder.buildEnumIriMapper(
                          context, iriInfo, mapperImportUri)
                      : DataBuilder.buildIriMapper(
                          context, iriInfo, mapperImportUri),
              LiteralInfo literalInfo => literalInfo.annotation.mapper != null
                  ? DataBuilder.buildCustomMapper(
                      context, literalInfo.className, literalInfo.annotation)
                  : literalInfo.enumValues.isNotEmpty
                      ? DataBuilder.buildEnumLiteralMapper(
                          context, literalInfo, mapperImportUri)
                      : DataBuilder.buildLiteralMapper(
                          context, literalInfo, mapperImportUri),
            })
        .map(MapperData.new)
        .toList();

    final allLibraryImports = resourceInfosWithElements
        .where((e) => e.$2 != null)
        .expand((e) => e.$2!.library2?.fragments ?? [])
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
