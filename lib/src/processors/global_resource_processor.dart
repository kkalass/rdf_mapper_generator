import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';

/// Processes class elements to extract RDF global resource information.
class GlobalResourceProcessor {
  /// Processes a class element to extract RDF global resource information.
  ///
  /// Returns a [GlobalResourceInfo] containing the processed information if the class is annotated
  /// with `@RdfGlobalResource`, otherwise returns `null`.
  static GlobalResourceInfo? processClass(ClassElement2 classElement) {
    final annotation = _getRdfGlobalResourceAnnotation(classElement);
    if (annotation == null) {
      return null;
    }

    final typeIri = _getTypeIri(annotation);
    final registerGlobally = _getRegisterGlobally(annotation);

    final className = classElement.displayName;
    final constructors = _extractConstructors(classElement);
    final fields = _extractFields(classElement);

    return GlobalResourceInfo(
      className: className,
      typeIri: typeIri,
      registerGlobally: registerGlobally,
      constructors: constructors,
      fields: fields,
    );
  }

  static DartObject? _getRdfGlobalResourceAnnotation(
      ClassElement2 classElement) {
    try {
      // Get metadata from the class element
      ;
      for (final elementAnnotation in classElement.metadata2.annotations) {
        try {
          final annotation = elementAnnotation.computeConstantValue();
          if (annotation != null) {
            final name = annotation.type?.element3?.name3;
            if (name == 'RdfGlobalResource') {
              return annotation;
            }
          }
        } catch (_) {
          // Ignore errors for individual annotations
          continue;
        }
      }
    } catch (_) {
      // Ignore errors during annotation processing
      return null;
    }

    return null;
  }

  static String _getTypeIri(DartObject annotation) {
    // First try to get the classIri field directly
    final classIriValue = annotation.getField('classIri');
    if (classIriValue != null && !classIriValue.isNull) {
      // The classIri is an IriTerm object, get its 'iri' field
      final iriValue = classIriValue.getField('iri');
      if (iriValue != null && !iriValue.isNull) {
        final value = iriValue.toStringValue();
        if (value != null) {
          return value;
        }
      }

      // If we can't get the iri field, try to get the string representation
      final stringValue = classIriValue.toStringValue();
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

        // Try direct string value
        final stringValue = firstArg.toStringValue();
        if (stringValue != null) {
          return stringValue;
        }
      }
    }

    // Try to get the type field directly
    final typeValue = annotation.getField('type');
    if (typeValue != null && !typeValue.isNull) {
      final stringValue = typeValue.toStringValue();
      if (stringValue != null) {
        return stringValue;
      }
    }

    // Finally, try the typeIri field as a fallback
    final typeIriValue = annotation.getField('typeIri');
    if (typeIriValue != null && !typeIriValue.isNull) {
      final value = typeIriValue.toStringValue();
      if (value != null) {
        return value;
      }
    }

    // If we get here, we couldn't find a type IRI
    throw StateError('Could not determine type IRI from annotation');
  }

  static List<DartObject> _getPositionalArguments(DartObject annotation) {
    try {
      // Try to access the positional arguments through the annotation's fields
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

      return [];
    } catch (e) {
      print('Error getting positional arguments: $e');
      return [];
    }
  }

  static bool _getRegisterGlobally(DartObject annotation) {
    try {
      final value = annotation.getField('registerGlobally');
      if (value != null && !value.isNull) {
        return value.toBoolValue() ?? true;
      }
      return true;
    } catch (_) {
      // Default to true if there's an error
      return true;
    }
  }

  static List<ConstructorInfo> _extractConstructors(
      ClassElement2 classElement) {
    final constructors = <ConstructorInfo>[];
    try {
      for (final constructor in classElement.constructors2) {
        final parameters = <ParameterInfo>[];

        for (final parameter in constructor.formalParameters) {
          parameters.add(ParameterInfo(
            name: parameter.name3!,
            type: parameter.type.getDisplayString(),
            isRequired: parameter.isRequired,
            isNamed: parameter.isNamed,
            isPositional: parameter.isPositional,
            isOptional: parameter.isOptional,
          ));
        }

        constructors.add(ConstructorInfo(
          name: constructor.displayName,
          isFactory: constructor.isFactory,
          isConst: constructor.isConst,
          isDefaultConstructor: constructor.isDefaultConstructor,
          parameters: parameters,
        ));
      }
    } catch (e) {
      print('Error extracting constructors: $e');
    }

    return constructors;
  }

  static List<FieldInfo> _extractFields(ClassElement2 classElement) {
    final fields = <FieldInfo>[];
    final typeSystem = classElement.library2.typeSystem;

    for (final field in classElement.fields2) {
      if (field.isStatic) continue;

      final propertyInfo = PropertyProcessor.processField(field);
      final isNullable = field.type.isDartCoreNull ||
          (field.type is InterfaceType &&
              (field.type as InterfaceType).isDartCoreNull) ||
          typeSystem.isNullable(field.type);

      fields.add(FieldInfo(
        name: field.name3!,
        type: field.type.getDisplayString(),
        isFinal: field.isFinal,
        isLate: field.isLate,
        isStatic: field.isStatic,
        isSynthetic: field.isSynthetic,
        propertyIri: propertyInfo?.propertyIri,
        isRequired: propertyInfo?.isRequired ?? !isNullable,
      ));
    }

    return fields;
  }
}
