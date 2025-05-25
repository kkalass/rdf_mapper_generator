import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';

/// Processes field elements to extract RDF property information.
class PropertyProcessor {
  /// Processes a field element to extract RDF property information.
  ///
  /// Returns a [PropertyInfo] if the field is annotated with `@RdfProperty`,
  /// otherwise returns `null`.
  static PropertyInfo? processField(FieldElement2 field) {
    final annotationObj = _getRdfPropertyAnnotation(field);
    if (annotationObj == null) {
      return null;
    }

    // Create an instance of RdfProperty from the annotation data
    final rdfProperty = _createRdfProperty(annotationObj);
    if (rdfProperty == null) {
      return null;
    }

    // Get the type system from the field's library
    final typeSystem = field.library2.typeSystem;

    // Check if the type is nullable
    final isNullable = field.type.isDartCoreNull ||
        (field.type is InterfaceType &&
            (field.type as InterfaceType).isDartCoreNull) ||
        typeSystem.isNullable(field.type);

    return PropertyInfo(
      name: field.name3!,
      type: field.type.getDisplayString(),
      annotation: rdfProperty,
      isRequired: !isNullable,
      isFinal: field.isFinal,
      isLate: field.isLate,
      isStatic: field.isStatic,
      isSynthetic: field.isSynthetic,
    );
  }

  static DartObject? _getRdfPropertyAnnotation(FieldElement2 field) {
    for (final metadata in field.metadata2.annotations) {
      final element = metadata.element2;
      if (element is ConstructorElement2) {
        final classElement = element.returnType.element3;
        if (classElement is ClassElement2 &&
            classElement.name3 == 'RdfProperty') {
          return metadata.computeConstantValue();
        }
      }
    }
    return null;
  }

  static RdfProperty? _createRdfProperty(DartObject annotation) {
    // Extract the predicate IRI
    final iriTerm = _extractIriTerm(annotation);
    if (iriTerm == null) {
      return null;
    }

    // Extract IRI mapping if present
    final iriMapping = _extractIriMapping(annotation);
    
    // Create and return the RdfProperty instance
    return RdfProperty(
      iriTerm,
      iri: iriMapping,
      // Add other parameters as needed
    );
  }

  
  static IriTerm? _extractIriTerm(DartObject annotation) {
    // First try to get the predicate field
    final predicateValue = annotation.getField('predicate');
    if (predicateValue != null && !predicateValue.isNull) {
      // Try to get the iri field from the predicate
      final iriValue = predicateValue.getField('iri');
      if (iriValue != null && !iriValue.isNull) {
        final iri = iriValue.toStringValue();
        if (iri != null) {
          return IriTerm(iri);
        }
      }
    }

    // Try to get the first positional argument
    final positionalArgs = _getPositionalArguments(annotation);
    if (positionalArgs.isNotEmpty) {
      final firstArg = positionalArgs.first;
      if (!firstArg.isNull) {
        // Check if it's an IriTerm
        final iriValue = firstArg.getField('iri');
        if (iriValue != null && !iriValue.isNull) {
          final value = iriValue.toStringValue();
          if (value != null) {
            return IriTerm(value);
          }
        }
      }
    }

    // Try to get the value field directly
    final valueField = annotation.getField('value');
    if (valueField != null && !valueField.isNull) {
      final stringValue = valueField.toStringValue();
      if (stringValue != null) {
        return IriTerm(stringValue);
      }
    }

    // Try to get the iri field directly as a fallback
    final iriField = annotation.getField('iri');
    if (iriField != null && !iriField.isNull) {
      final value = iriField.toStringValue();
      if (value != null) {
        return IriTerm(value);
      }
    }

    // If we get here, we couldn't find a valid IRI
    return null;
  }
  
  static IriMapping? _extractIriMapping(DartObject annotation) {
    // Check for named parameter 'iri'
    final iriMapping = annotation.getField('iri');
    if (iriMapping != null && !iriMapping.isNull) {
      // Check if it's an IriMapping
      final template = iriMapping.getField('template');
      if (template != null && !template.isNull) {
        final templateStr = template.toStringValue();
        if (templateStr != null) {
          return IriMapping(templateStr);
        }
      }
    }
    return null;
  }
  
  static List<DartObject> _getPositionalArguments(DartObject annotation) {
    try {
      final type = annotation.type;
      if (type != null) {
        final element = type.element3;
        if (element is ClassElement2) {
          // Look for a field that might contain the positional arguments
          for (final field in element.fields2) {
            if (field.name3 == '_positionalArguments' ||
                field.name3 == 'values') {
              final value = annotation.getField(field.name3!);
              if (value != null && !value.isNull) {
                return value.toListValue() ?? [];
              }
            }
          }
        }
      }

      // As a fallback, try to get the first positional argument directly
      final value = annotation.getField('value');
      if (value != null && !value.isNull) {
        return [value];
      }
    } catch (e) {
      print('Error getting positional arguments: $e');
    }
    return [];
  }
}
