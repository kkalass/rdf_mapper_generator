import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';

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

IriTerm? getIriTerm(DartObject annotation, String fieldName) {
  try {
    final classIriValue = annotation.getField(fieldName);
    if (classIriValue != null && !classIriValue.isNull) {
      // Get the IRI string from the IriTerm
      final iriValue = classIriValue.getField('iri')?.toStringValue();
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
