import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Processes class elements to extract @RdfIri information.
class IriProcessor {
  /// Processes a class element and returns its ResourceInfo if it's annotated with @RdfGlobalResource or @RdfLocalResource.
  ///
  /// Returns a [MappableClassInfo] containing the processed information if the class is annotated
  /// with `@RdfIri`, otherwise returns `null`.
  static IriInfo? processClass(
      ValidationContext context, ClassElement2 classElement) {
    final annotation =
        getAnnotation(classElement.metadata2.annotations, 'RdfIri');
    final className = classToCode(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfIriAnnotation =
        _createRdfIriAnnotation(context, annotation, classElement);
    if (rdfIriAnnotation == null) {
      return null; // No valid resource annotation found
    }
    final fields = extractFields(context, classElement);
    final constructors = extractConstructors(
        classElement, fields, rdfIriAnnotation.templateInfo);

    return IriInfo(
      className: className,
      annotation: rdfIriAnnotation,
      constructors: constructors,
      fields: fields,
    );
  }

  static RdfIriInfo? _createRdfIriAnnotation(ValidationContext context,
      DartObject? annotation, ClassElement2 classElement) {
    try {
      if (annotation == null) {
        return null;
      }

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<IriTermMapper>(annotation);

      // Get the iriStrategy from the annotation
      final templateFieldValue =
          getField(annotation, 'template')?.toStringValue();
      final (template, templateInfo, iriParts) =
          IriStrategyProcessor.processIriPartsAndTemplate(
              context, classElement, templateFieldValue, mapper);

      // Create and return the RdfGlobalResource instance
      return RdfIriInfo(
          registerGlobally: registerGlobally,
          mapper: mapper,
          template: template,
          iriParts: iriParts,
          templateInfo: templateInfo);
    } catch (e) {
      print('Error creating RdfGlobalResource: $e');
      rethrow;
    }
  }
}
