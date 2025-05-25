import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';

/// Processes class elements to extract RDF global resource information.
class GlobalResourceProcessor {
  /// Processes a class element to extract RDF global resource information.
  ///
  /// Returns a [GlobalResourceInfo] containing the processed information if the class is annotated
  /// with `@RdfGlobalResource`, otherwise returns `null`.
  static GlobalResourceInfo? processClass(ClassElement classElement) {
    print('Processing class: ${classElement.name}');
    
    final annotation = _getRdfGlobalResourceAnnotation(classElement);
    if (annotation == null) {
      print('No RdfGlobalResource annotation found');
      return null;
    }
    
    print('Found RdfGlobalResource annotation!');
    
    // Debug: Print all fields and their values
    print('Annotation fields:');
    final type = annotation.type;
    if (type != null) {
      final element = type.element;
      if (element is InterfaceElement) {
        for (final field in element.fields) {
          final value = annotation.getField(field.name);
          print('  ${field.name}: ${value?.toString() ?? 'null'} (${value?.type?.getDisplayString() ?? 'unknown type'})');
        }
      }
    }
    
    final typeIri = _getTypeIri(annotation);
    final registerGlobally = _getRegisterGlobally(annotation);
    
    print('Extracted values:');
    print('  typeIri: $typeIri');
    print('  registerGlobally: $registerGlobally');
    
    final className = classElement.name;
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

  static DartObject? _getRdfGlobalResourceAnnotation(ClassElement classElement) {
    try {
      final className = classElement.name;
      print('Processing class: $className');
      
      // Get metadata from the class element
      for (final metadata in classElement.metadata) {
        try {
          final annotation = metadata.computeConstantValue();
          if (annotation != null) {
            final name = annotation.type?.name;
            if (name == 'RdfGlobalResource') {
              print('Found RdfGlobalResource annotation!');
              return annotation;
            }
          }
        } catch (e) {
          print('Error processing annotation: $e');
        }
      }
    } catch (e) {
      print('Error in _getRdfGlobalResourceAnnotation: $e');
    }
    
    return null;
  }

  static String _getTypeIri(DartObject annotation) {
    try {
      // First try to get the classIri field directly
      final classIriValue = annotation.getField('classIri');
      if (classIriValue != null && !classIriValue.isNull) {
        // The classIri is an IriTerm object, get its 'iri' field
        final iriValue = classIriValue.getField('iri');
        if (iriValue != null && !iriValue.isNull) {
          final value = iriValue.toStringValue();
          if (value != null) {
            print('Found IRI in classIri.iri: $value');
            return value;
          }
        }
        
        // If we can't get the iri field, try to get the string representation
        final stringValue = classIriValue.toStringValue();
        if (stringValue != null) {
          print('Found classIri as string: $stringValue');
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
              print('Found IRI in first positional argument: $value');
              return value;
            }
          }
          
          // Try direct string value
          final stringValue = firstArg.toStringValue();
          if (stringValue != null) {
          }
        }
      }
      
      // Try to get the type field directly
      final typeValue = annotation.getField('type');
      if (typeValue != null && !typeValue.isNull) {
        final stringValue = typeValue.toStringValue();
        if (stringValue != null) {
          print('Found string in type field: $stringValue');
          return stringValue;
        }
      }
      
      // Finally, try the typeIri field as a fallback
      final typeIriValue = annotation.getField('typeIri');
      if (typeIriValue != null && !typeIriValue.isNull) {
        final value = typeIriValue.toStringValue();
        if (value != null) {
          print('Found typeIri: $value');
          return value;
        }
      }
      
      // If we get here, we couldn't find a type IRI
      print('Error: Could not determine type IRI from annotation');
      throw StateError('Could not determine type IRI from annotation');
    } catch (e) {
      print('Error getting type IRI: $e');
      throw StateError('Error getting type IRI: $e');
    }
  }
  
  static List<DartObject> _getPositionalArguments(DartObject annotation) {
    try {
      // Try to access the positional arguments through the annotation's fields
      final type = annotation.type;
      if (type != null) {
        final element = type.element;
        if (element is InterfaceElement) {
          // Look for a field that might contain the positional arguments
          for (final field in element.fields) {
            if (field.name == '_positionalArguments' || field.name == 'values') {
              final value = annotation.getField(field.name);
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
    } catch (e) {
      print('Error getting registerGlobally: $e');
      return true;
    }
  }

  static List<ConstructorInfo> _extractConstructors(ClassElement classElement) {
    final constructors = <ConstructorInfo>[];
    try {
      for (final constructor in classElement.constructors) {
        final parameters = <ParameterInfo>[];
        
        for (final parameter in constructor.parameters) {
          parameters.add(ParameterInfo(
            name: parameter.name,
            type: parameter.type.getDisplayString(),
            isRequired: parameter.isRequired,
            isNamed: parameter.isNamed,
            isPositional: parameter.isPositional,
            isOptional: parameter.isOptional,
          ));
        }
        
        constructors.add(ConstructorInfo(
          name: constructor.name,
          isFactory: constructor.isFactory,
          isConst: constructor.isConst,
          isDefaultConstructor: constructor.name == '',
          parameters: parameters,
        ));
      }
    } catch (e) {
      print('Error extracting constructors: $e');
    }
    
    return constructors;
  }

  static List<FieldInfo> _extractFields(ClassElement classElement) {
    final fields = <FieldInfo>[];
    try {
      for (final field in classElement.fields) {
        fields.add(FieldInfo(
          name: field.name,
          type: field.type.getDisplayString(),
          isFinal: field.isFinal,
          isLate: field.isLate,
          isStatic: field.isStatic,
          isSynthetic: field.isSynthetic,
        ));
      }
    } catch (e) {
      print('Error extracting fields: $e');
    }
    
    return fields;
  }
}
