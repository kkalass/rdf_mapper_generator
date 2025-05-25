import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';

/// Processes field elements to extract RDF property information.
class PropertyProcessor {
  /// Processes a field element to extract RDF property information.
  ///
  /// Returns a [PropertyInfo] if the field is annotated with `@RdfProperty`,
  /// otherwise returns `null`.
  static PropertyInfo? processField(FieldElement2 field) {
    final annotation = _getRdfPropertyAnnotation(field);
    if (annotation == null) {
      return null;
    }

    final propertyIri = _getPropertyIri(annotation);
    if (propertyIri == null) {
      return null;
    }

    final iriMapping = _getIriMapping(annotation);

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
      propertyIri: propertyIri,
      isRequired: !isNullable,
      isFinal: field.isFinal,
      isLate: field.isLate,
      isStatic: field.isStatic,
      isSynthetic: field.isSynthetic,
      iriMapping: iriMapping,
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

  static String? _getPropertyIri(DartObject annotation) {
    // First try to get the predicate field
    final predicateValue = annotation.getField('predicate');
    if (predicateValue != null && !predicateValue.isNull) {
      // Try to get the iri field from the predicate
      final iriValue = predicateValue.getField('iri');
      if (iriValue != null && !iriValue.isNull) {
        final iri = iriValue.toStringValue();
        if (iri != null) {
          return iri;
        }
      }

      // If we can't get the iri field, try to get the string representation
      final stringValue = predicateValue.toStringValue();
      if (stringValue != null) {
        return stringValue;
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
            return value;
          }
        }

        // If we can't get the iri field, try to get the string representation
        final stringValue = firstArg.toStringValue();
        if (stringValue != null) {
          return stringValue;
        }
      }
    }

    // Try to get the value field directly
    final valueField = annotation.getField('value');
    if (valueField != null && !valueField.isNull) {
      final stringValue = valueField.toStringValue();
      if (stringValue != null) {
        return stringValue;
      }
    }

    // Try to get the iri field directly as a fallback
    final iriField = annotation.getField('iri');
    if (iriField != null && !iriField.isNull) {
      final value = iriField.toStringValue();
      if (value != null) {
        return value;
      }
    }

    // If we get here, we couldn't find a property IRI
    return null;
  }

  static String? _getIriMapping(DartObject annotation) {
    // Check for named parameter 'iri'
    final iriMapping = annotation.getField('iri');
    if (iriMapping != null && !iriMapping.isNull) {
      // Check if it's an IriMapping
      final template = iriMapping.getField('template');
      if (template != null && !template.isNull) {
        return template.toStringValue();
      }

      // Try direct string value
      return iriMapping.toStringValue();
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
