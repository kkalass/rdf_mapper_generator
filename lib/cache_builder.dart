import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';

Builder rdfMapperCacheBuilder(BuilderOptions options) =>
    RdfMapperCacheBuilder();

/// First phase builder that generates cache files with template data.
/// This builder runs before the main builder and stores the template data in JSON format.
class RdfMapperCacheBuilder implements Builder {
  static final _builderHelper = BuilderHelper();

  @override
  Future<void> build(BuildStep buildStep) => buildIt(
      buildStep.inputId,
      buildStep.readAsString,
      buildStep.writeAsString,
      (inputId, {bool allowSyntaxErrors = false}) async => (await buildStep
              .resolver
              .libraryFor(inputId, allowSyntaxErrors: allowSyntaxErrors))
          // The library element from build system is LibraryElement, cast to Element2
          as LibraryElement2);

  Future<void> buildIt(
      AssetId inputId,
      Future<String> Function(AssetId id, {Encoding encoding}) readAsString,
      Future<void> Function(AssetId id, FutureOr<String> contents,
              {Encoding encoding})
          writeAsString,
      Future<LibraryElement2> Function(AssetId assetId,
              {bool allowSyntaxErrors})
          libraryFor) async {
    // Only process .dart files, skip generated files
    if (!inputId.path.endsWith('.dart') ||
        inputId.path.contains('.g.dart') ||
        inputId.path.contains('.rdf_mapper.g.dart')) {
      return;
    }

    try {
      final sourceContent = await readAsString(inputId);

      // Parse the source file using the analyzer
      final parseResult = parseString(
        content: sourceContent,
        path: inputId.path,
      );

      if (parseResult.errors.isNotEmpty) {
        log.warning(
          'Parse errors in ${inputId.path}: ${parseResult.errors}',
        );
        return;
      }

      // Get the library element for the parsed file
      final library = await _resolveLibrary(libraryFor, inputId);
      if (library == null) {
        return;
      }

      final classes = library.fragments
          .expand((f) => f.classes2)
          .map((c) => c.element)
          .toList();

      final enums = library.fragments
          .expand((f) => f.enums2)
          .map((e) => e.element)
          .toList();

      final generatedTemplateData = await _builderHelper.buildTemplateData(
          inputId.path,
          inputId.package,
          classes,
          enums,
          BroaderImports.create(library));

      // Only create output file if we generated code
      if (generatedTemplateData != null) {
        final outputId = inputId.changeExtension('.rdf_mapper.cache.json');
        await writeAsString(outputId, jsonEncode(generatedTemplateData));

        log.info('Generated RDF mapper cache for ${inputId.path}');
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error processing ${inputId.path}: $e',
        e,
        stackTrace,
      );
      // Re-throw to ensure build fails on errors
      rethrow;
    }
  }

  /// Resolves the library for the current build step.
  Future<LibraryElement2?> _resolveLibrary(
      Future<LibraryElement2> Function(AssetId assetId,
              {bool allowSyntaxErrors})
          libraryFor,
      AssetId inputId) async {
    try {
      // For build system integration, we need to use the resolver
      return await libraryFor(inputId);
    } catch (e) {
      log.warning('Could not resolve library for ${inputId.path}: $e');
      return null;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rdf_mapper.cache.json']
      };
}
