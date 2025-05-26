import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/processors/parse_utils.dart';
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

    final className = classElement.displayName;
    final constructors = _extractConstructors(classElement);
    final fields = _extractFields(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfGlobalResource = _createRdfGlobalResource(annotation);

    return GlobalResourceInfo(
      className: className,
      annotation: rdfGlobalResource,
      constructors: constructors,
      fields: fields,
    );
  }

  static DartObject? _getRdfGlobalResourceAnnotation(
          ClassElement2 classElement) =>
      getAnnotation(classElement, 'RdfGlobalResource');

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
              final value = getField(annotation, field.name3!);
              if (value != null && !value.isNull) {
                return value.toListValue() ?? [];
              }
            }
          }
        }
      }

      // As a fallback, try to get the first positional argument directly
      final value = getField(annotation, 'value');
      if (value != null && !value.isNull) {
        return [value];
      }

      return [];
    } catch (e) {
      print('Error getting positional arguments: $e');
      return [];
    }
  }

  static RdfGlobalResourceInfo _createRdfGlobalResource(DartObject annotation) {
    try {
      // Get the classIri from the annotation
      final classIri = _getClassIri(annotation);

      // Get the iriStrategy from the annotation
      final iriStrategy = _getIriStrategy(annotation);

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<GlobalResourceMapper>(annotation);

      // Create and return the RdfGlobalResource instance
      return RdfGlobalResourceInfo(
        classIri: classIri,
        iri: iriStrategy,
        registerGlobally: registerGlobally,
        mapper: mapper,
      );
    } catch (e) {
      print('Error creating RdfGlobalResource: $e');
      rethrow;
    }
  }

  static IriTerm? _getClassIri(DartObject annotation) {
    try {
      final classIri = getIriTerm(annotation, 'classIri');
      if (classIri != null) {
        return classIri;
      }

      // Try to get from positional arguments (first argument is classIri)
      final positionalArgs = _getPositionalArguments(annotation);
      if (positionalArgs.isNotEmpty) {
        final firstArg = positionalArgs.first;
        if (!firstArg.isNull) {
          // Check if it's an IriTerm with an 'iri' field
          final iriValue = getField(firstArg, 'iri')?.toStringValue();
          if (iriValue != null) {
            return IriTerm(iriValue);
          }

          // Try direct string value
          final stringValue = firstArg.toStringValue();
          if (stringValue != null) {
            return IriTerm(stringValue);
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting class IRI: $e');
      return null;
    }
  }

  static IriStrategyInfo? _getIriStrategy(DartObject annotation) {
    // Check if we have an iri field (for the standard constructor)
    final iriValue = getField(annotation, 'iri');
    if (iriValue == null || iriValue.isNull) {
      return null;
    }
    final template = getField(iriValue, 'template')?.toStringValue();
    final mapper = getMapperRefInfo<IriTermMapper>(iriValue);
    return IriStrategyInfo(mapper: mapper, template: template);
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
