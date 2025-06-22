import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

/// Contains information about an IRI source reference including the
/// source code expression and required import.
class IriTermInfo {
  /// The source code expression (e.g., 'SchemaBook.classIri' or 'IriTerm("https://schema.org/Book")')
  final Code code;

  /// The actual IRI value for fallback purposes
  final IriTerm value;

  const IriTermInfo({
    required this.code,
    required this.value,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriTermInfo && other.code == code && other.value == value;
  }

  @override
  int get hashCode => Object.hash(
        code,
        value,
      );

  @override
  String toString() => 'IriTermInfo(code: $code, '
      'value: $value)';
}

DartObject? getAnnotation(Metadata metadata2, String annotationName) {
  try {
    // Get metadata from the class element
    ;
    for (final elementAnnotation in metadata2.annotations) {
      try {
        final annotation = elementAnnotation.computeConstantValue();
        if (annotation != null) {
          final name = annotation.type?.element3?.name3;
          if (name == annotationName) {
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

bool isNull(DartObject? field) {
  return field == null || field.isNull;
}

MapperRefInfo<M>? getMapperRefInfo<M>(DartObject annotation) {
  final nameField = getField(annotation, '_mapperName');
  final typeField = getField(annotation, '_mapperType');
  final instanceField = getField(annotation, '_mapperInstance');
  final name = nameField?.toStringValue();
  if (isNull(nameField) && isNull(typeField) && isNull(instanceField)) {
    return null;
  }
  return MapperRefInfo(name: name, type: typeField, instance: instanceField);
}

bool isRegisterGlobally(DartObject annotation) {
  final field = getField(annotation, 'registerGlobally');
  return field?.toBoolValue() ?? true;
}

/**
 * Gets the field - unlike obj.getField() we will go up the 
 * inheritance tree to find a parent with the field of the specified name
 * if needed.
 */
DartObject? getField(DartObject obj, String fieldName) {
  final field = obj.getField(fieldName);
  if (field != null && !field.isNull) {
    return field;
  }
  final superInstance = obj.getField('(super)');
  if (superInstance == null) {
    return null;
  }
  return getField(superInstance, fieldName);
}

E getEnumFieldValue<E extends Enum>(
    DartObject annotation, String fieldName, List<E> values, E defaultValue) {
  final collectionField = getField(annotation, 'collection');

  // Extract enum constant name - toStringValue() returns null for enums,
  // so we need to access the variable element's name
  final collectionValue = collectionField?.variable2?.name3;

  final collection = collectionValue == null
      ? defaultValue
      : values.firstWhere((e) => e.name == collectionValue);
  return collection;
}

IriTerm? getIriTerm(DartObject? iriTermObject) {
  try {
    if (iriTermObject != null && !iriTermObject.isNull) {
      // Get the IRI string from the IriTerm
      final iriValue = iriTermObject.getField('iri')?.toStringValue();
      if (iriValue != null) {
        return IriTerm(iriValue);
      }
    }

    return null;
  } catch (e) {
    print('Error getting class IRI: $e');
    return null;
  }
}

/// Gets the source code reference for an IRI field, preserving the original expression
/// and determining the required import.
/// This is used to maintain references like 'SchemaBook.classIri' instead of
/// evaluating them to literal values.
IriTermInfo? getIriTermInfo(DartObject? iriTermObject) {
  try {
    if (iriTermObject != null && !iriTermObject.isNull) {
      // Get the actual IRI value for fallback
      final iriTerm = getIriTerm(iriTermObject)!;

      // Try to get the source reference from the variable element
      final code = toCode(iriTermObject);

      return IriTermInfo(
        code: code,
        value: iriTerm,
      );
    }
    return null;
  } catch (e) {
    print('Error getting IRI source reference: $e');
    return null;
  }
}

Map<String, String> _getIriPartNameByPropertyName(
        IriTemplateInfo? templateInfo) =>
    templateInfo == null
        ? {}
        : {
            for (var pv in templateInfo.propertyVariables)
              pv.dartPropertyName: pv.name
          };

List<ConstructorInfo> extractConstructors(ClassElement2 classElement,
    List<FieldInfo> fields, IriTemplateInfo? iriTemplateInfo) {
  final iriPartNameByPropertyName =
      _getIriPartNameByPropertyName(iriTemplateInfo);

  final constructors = <ConstructorInfo>[];
  try {
    final fieldsByName = {for (final field in fields) field.name: field};

    for (final constructor in classElement.constructors2) {
      final parameters = <ParameterInfo>[];

      for (final parameter in constructor.formalParameters) {
        // Find the corresponding field with @RdfProperty annotation, if it exists
        final fieldInfo = fieldsByName[parameter.name3!];

        parameters.add(ParameterInfo(
          name: parameter.name3!,
          type: typeToCode(parameter.type),
          isRequired: parameter.isRequired,
          isNamed: parameter.isNamed,
          isPositional: parameter.isPositional,
          isOptional: parameter.isOptional,
          propertyInfo: fieldInfo?.propertyInfo,
          isIriPart: iriPartNameByPropertyName.containsKey(parameter.name3!),
          iriPartName: iriPartNameByPropertyName[parameter.name3!],
          isRdfLanguageTag: fieldInfo?.isRdfLanguageTag ?? false,
          isRdfValue: fieldInfo?.isRdfValue ?? false,
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

List<FieldInfo> extractFields(ClassElement2 classElement) {
  final fields = <FieldInfo>[];
  final typeSystem = classElement.library2.typeSystem;

  for (final field in classElement.fields2) {
    if (field.isStatic) continue;

    final propertyInfo = PropertyProcessor.processField(field);
    final isNullable = field.type.isDartCoreNull ||
        (field.type is InterfaceType &&
            (field.type as InterfaceType).isDartCoreNull) ||
        typeSystem.isNullable(field.type);
    final isRdfValue = getAnnotation(field.metadata2, 'RdfValue') != null;
    final isRdfLanguageTag =
        getAnnotation(field.metadata2, 'RdfLanguageTag') != null;

    fields.add(FieldInfo(
      name: field.name3!,
      type: typeToCode(field.type),
      isFinal: field.isFinal,
      isLate: field.isLate,
      isStatic: field.isStatic,
      isSynthetic: field.isSynthetic,
      propertyInfo: propertyInfo,
      isRequired: propertyInfo?.isRequired ?? !isNullable,
      isRdfLanguageTag: isRdfLanguageTag,
      isRdfValue: isRdfValue,
    ));
  }

  return fields;
}
