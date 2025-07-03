import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('ResourceProcessor');

/// Processes class elements to extract RDF global and local resource information.
class ResourceProcessor {
  /// Processes a class element and returns its ResourceInfo if it's annotated with @RdfGlobalResource or @RdfLocalResource.
  ///
  /// Returns a [MappableClassInfo] containing the processed information if the class is annotated
  /// with `@RdfGlobalResource` or `@RdfLocalResource`, otherwise returns `null`.
  static ResourceInfo? processClass(
      ValidationContext context, ClassElement2 classElement) {
    final globalResourceAnnotation =
        getAnnotation(classElement.metadata2.annotations, 'RdfGlobalResource');
    final localResourceAnnotation =
        getAnnotation(classElement.metadata2.annotations, 'RdfLocalResource');
    final className = classToCode(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfResource = _createRdfResource(context, globalResourceAnnotation,
        localResourceAnnotation, classElement);
    if (rdfResource == null) {
      return null; // No valid resource annotation found
    }

    final fields = extractFields(context, classElement);
    final constructors = extractConstructors(
        classElement,
        fields,
        switch (rdfResource) {
          RdfGlobalResourceInfo _ => rdfResource.iri?.templateInfo,
          RdfLocalResourceInfo _ => null,
        });
    final rdfMapValue =
        extractMapValueAnnotation(classElement.metadata2.annotations);
    return ResourceInfo(
        className: className,
        annotation: rdfResource,
        constructors: constructors,
        fields: fields,
        rdfMapValue: rdfMapValue);
  }

  static RdfResourceInfo? _createRdfResource(
      ValidationContext context,
      DartObject? globalResourceAnnotation,
      DartObject? localResourceAnnotation,
      ClassElement2 classElement) {
    try {
      if (globalResourceAnnotation != null && localResourceAnnotation != null) {
        context.addError(
          'Class ${classElement.name3} cannot be annotated with both @RdfGlobalResource and @RdfLocalResource.',
        );
        return null;
      }

      final annotation = globalResourceAnnotation ?? localResourceAnnotation;
      final isGlobalResource = globalResourceAnnotation != null;
      if (annotation == null) {
        return null;
      }

      // Get the classIri from the annotation
      final classIri = getIriTermInfo(getField(annotation, 'classIri'));

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<GlobalResourceMapper>(annotation);

      if (isGlobalResource) {
        // Get the iriStrategy from the annotation
        final iriStrategy = _getIriStrategy(context, annotation, classElement);
        // Create and return the RdfGlobalResource instance
        return RdfGlobalResourceInfo(
          classIri: classIri,
          iri: iriStrategy,
          registerGlobally: registerGlobally,
          mapper: mapper,
        );
      }
      // Create and return the RdfGlobalResource instance
      return RdfLocalResourceInfo(
        classIri: classIri,
        registerGlobally: registerGlobally,
        mapper: mapper,
      );
    } catch (e) {
      _log.severe('Error creating RdfGlobalResource', e);
      rethrow;
    }
  }

  static IriStrategyInfo? _getIriStrategy(ValidationContext context,
      DartObject annotation, ClassElement2 classElement) {
    // Check if we have an iri field (for the standard constructor)
    final iriValue = getField(annotation, 'iri');
    if (iriValue == null || iriValue.isNull) {
      return null;
    }
    return IriStrategyProcessor.processIriStrategy(
        context, iriValue, classElement);
  }
}
