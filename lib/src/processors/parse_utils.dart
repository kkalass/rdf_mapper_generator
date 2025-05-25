import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';

DartObject? getAnnotation(ClassElement2 classElement, String annotationName) {
  try {
    // Get metadata from the class element
    ;
    for (final elementAnnotation in classElement.metadata2.annotations) {
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

MapperRefInfo<M>? getMapperRefInfo<M>(DartObject annotation) {
  // FIXME MapperRefInfo
}

bool isRegisterGlobally(DartObject annotation) =>
    annotation.getField('registerGlobally')?.toBoolValue() ?? true;

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
