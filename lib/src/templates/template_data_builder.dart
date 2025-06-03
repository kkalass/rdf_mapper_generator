import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as path;
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/global_resource_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';

/// Builds template data from processed resource information.
class TemplateDataBuilder {
  /// Builds file template data for multiple global resource mappers.
  static FileTemplateData buildFileTemplate(
    String sourcePath,
    List<(MappableClassInfo, ClassElement2)> resourceInfosWithElements,
  ) {
    final header = FileHeaderData(
      sourcePath: sourcePath,
      generatedOn: DateTime.now().toIso8601String(),
    );

    // Collect all imports from all mappers and deduplicate
    final allImports = <String>{};
    final mapperDatas = <MapperData>[];

    for (final (resourceInfo, classElement) in resourceInfosWithElements) {
      final MappableClassMapperTemplateData mapperData = switch (resourceInfo) {
        GlobalResourceInfo _ =>
          GlobalResourceDataBuilder.buildGlobalResourceMapper(resourceInfo),
      };

      // Add imports from this mapper
      allImports.addAll(mapperData.imports.map((i) => i.import));

      // Add source file import for the model class
      // Generate the expected output file path from the source path
      final generatedFilePath =
          sourcePath.replaceAll('.dart', '.rdf_mapper.g.dart');
      final sourceImport =
          _buildSourceFileImport(classElement, generatedFilePath);
      if (sourceImport != null) {
        allImports.add(sourceImport);
      }

      mapperDatas.add(MapperData(mapperData));
    }

    final imports = allImports.map(ImportData.new).toList();

    return FileTemplateData(
      header: header,
      imports: imports,
      mappers: mapperDatas,
    );
  }

  /// Builds the source file import for the model class.
  static String? _buildSourceFileImport(
    ClassElement2 classElement,
    String generatedFilePath,
  ) {
    // Access the library identifier which contains the source package/file information
    final libraryIdentifier = classElement.library2.identifier;
    // Extract just the filename part from the library identifier
    final String lastPart;

    // Handle possible scheme prefixes (package:, asset:, file:)
    if (libraryIdentifier.contains('/')) {
      lastPart = libraryIdentifier.split('/').last;
    } else {
      lastPart = libraryIdentifier;
    }

    // If the last part is a Dart file, use it as the import
    return lastPart.endsWith('.dart') ? lastPart : null;
  }
}
