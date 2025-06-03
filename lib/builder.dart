import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';

Builder rdfMapperBuilder(BuilderOptions options) => RdfMapperBuilder();

/// Builder that processes RDF annotations and generates mapper classes using mustache templates.
///
/// This builder scans Dart files for classes annotated with @RdfGlobalResource and generates
/// corresponding mapper classes that handle serialization/deserialization between Dart objects
/// and RDF triples.
class RdfMapperBuilder implements Builder {
  static final _builderHelper = BuilderHelper();

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only process .dart files, skip generated files
    if (!buildStep.inputId.path.endsWith('.dart') ||
        buildStep.inputId.path.contains('.g.dart') ||
        buildStep.inputId.path.contains('.rdf_mapper.g.dart')) {
      return;
    }

    try {
      final sourceContent = await buildStep.readAsString(buildStep.inputId);

      // Parse the source file using the analyzer
      final parseResult = parseString(
        content: sourceContent,
        path: buildStep.inputId.path,
      );

      if (parseResult.errors.isNotEmpty) {
        log.warning(
          'Parse errors in ${buildStep.inputId.path}: ${parseResult.errors}',
        );
        return;
      }

      // Get the library element for the parsed file
      final library = await _resolveLibrary(buildStep);
      if (library == null) {
        return;
      }

      final libsByClassName = LibsByClassName.create(library);

      final classes = library.fragments
          .expand((f) => f.classes2)
          .map((c) => c.element)
          .toList();

      final generatedCode = await _builderHelper.build(
        buildStep.inputId.path,
        classes,
        libsByClassName,
        buildStep,
      );

      // Only create output file if we generated code
      if (generatedCode != null) {
        final outputId =
            buildStep.inputId.changeExtension('.rdf_mapper.g.dart');
        await buildStep.writeAsString(outputId, generatedCode);

        log.info('Generated RDF mapper for ${buildStep.inputId.path}');
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error processing ${buildStep.inputId.path}: $e',
        e,
        stackTrace,
      );
      // Re-throw to ensure build fails on errors
      rethrow;
    }
  }

  /// Resolves the library for the current build step.
  Future<LibraryElement2?> _resolveLibrary(BuildStep buildStep) async {
    try {
      // For build system integration, we need to use the resolver
      final resolver = buildStep.resolver;
      final library = await resolver.libraryFor(buildStep.inputId);

      // The library element from build system is LibraryElement, cast to Element2
      return library as LibraryElement2;
    } catch (e) {
      log.warning(
          'Could not resolve library for ${buildStep.inputId.path}: $e');
      return null;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.rdf_mapper.g.dart']
      };
}
