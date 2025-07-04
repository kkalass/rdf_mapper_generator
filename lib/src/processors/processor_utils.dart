// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
// import 'package:analyzer/dart/element/type.dart';
// import 'package:analyzer/dart/element/type_system.dart';
import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('ProcessorUtils');

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

DartObject? getAnnotation(
    Iterable<ElemAnnotation> annotations, String annotationName) {
  try {
    // Get metadata from the class element
    ;
    for (final elementAnnotation in annotations) {
      try {
        final annotation = elementAnnotation.computeConstantValue();
        if (annotation != null) {
          final name = annotation.type?.element.name;
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

IriPartAnnotationInfo? extractIriPartAnnotation(
    String fieldName, Iterable<ElemAnnotation> annotations) {
  // Check for @RdfIriPart annotation
  final iriPartAnnotation = getAnnotation(annotations, 'RdfIriPart');
  if (iriPartAnnotation == null) {
    return null;
  }
  final name = getFieldStringValue(iriPartAnnotation, 'name') ?? fieldName;
  final pos = getField(iriPartAnnotation, 'pos')?.toIntValue() ?? 0;
  return IriPartAnnotationInfo(
    name: name,
    pos: pos,
  );
}

RdfMapEntryAnnotationInfo? extractMapEntryAnnotation(ValidationContext context,
    String fieldName, Iterable<ElemAnnotation> annotations) {
  // Check for @RdfMapEntry annotation
  final mapEntryAnnotation = getAnnotation(annotations, 'RdfMapEntry');
  if (mapEntryAnnotation == null) {
    return null;
  }
  final itemClass = getField(mapEntryAnnotation, 'itemClass');
  final itemClassType = itemClass?.toTypeValue();
  if (itemClassType == null) {
    context.addError(
        'RdfMapEntry annotation on field $fieldName must specify a type for itemClass');
    return null;
  }
  final itemType = typeToCode(itemClassType);
  final itemClassTypeElement =
      itemClassType.isInterfaceType ? itemClassType.element : null;
  final ClassElem? itemClassElement =
      itemClassTypeElement is ClassElem ? itemClassTypeElement : null;
  if (itemClassElement == null) {
    context.addError(
        'RdfMapEntry annotation on field $fieldName must specify a class for itemClass');
    return null;
  }
  return RdfMapEntryAnnotationInfo(
    itemType: itemType,
    itemClassElement: itemClassElement,
    itemClassType: itemClassType,
  );
}

RdfMapKeyAnnotationInfo? extractMapKeyAnnotation(
    Iterable<ElemAnnotation> annotations) {
  final mapKeyAnnotation = getAnnotation(annotations, 'RdfMapKey');
  return mapKeyAnnotation == null ? null : RdfMapKeyAnnotationInfo();
}

RdfMapValueAnnotationInfo? extractMapValueAnnotation(
    Iterable<ElemAnnotation> annotations) {
  final mapValueAnnotation = getAnnotation(annotations, 'RdfMapValue');
  return mapValueAnnotation == null ? null : RdfMapValueAnnotationInfo();
}

bool isNull(DartObject? field) {
  return field == null || field.isNull;
}

MapperRefInfo<M>? getMapperRefInfo<M>(DartObject annotation) {
  final typeField = getField(annotation, '_mapperType');
  final instanceField = getField(annotation, '_mapperInstance');
  final name = getFieldStringValue(annotation, '_mapperName');
  if (name == null && isNull(typeField) && isNull(instanceField)) {
    return null;
  }
  return MapperRefInfo(
      name: name,
      type: isNull(typeField) ? null : typeToCode(typeField!.toTypeValue()!),
      instance: instanceField);
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

String? getFieldStringValue(DartObject obj, String fieldName) {
  final retval = getField(obj, fieldName)?.toStringValue();
  return retval == null || retval.isEmpty ? null : retval;
}

E getEnumFieldValue<E extends Enum>(
    DartObject annotation, String fieldName, List<E> values, E defaultValue) {
  final collectionField = getField(annotation, 'collection');

  // Extract enum constant name - toStringValue() returns null for enums,
  // so we need to access the variable element's name
  final collectionValue = collectionField?.variable?.name;

  final collection = collectionValue == null
      ? defaultValue
      : values.firstWhere((e) => e.name == collectionValue);
  return collection;
}

IriTerm? getIriTerm(DartObject? iriTermObject) {
  try {
    if (iriTermObject != null && !iriTermObject.isNull) {
      // Get the IRI string from the IriTerm
      final iriValue = getFieldStringValue(iriTermObject, 'iri');
      if (iriValue != null) {
        return IriTerm(iriValue);
      }
    }

    return null;
  } catch (e, stackTrace) {
    _log.severe('Error getting class IRI', e, stackTrace);
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
    _log.severe('Error getting IRI source reference', e);
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

List<ConstructorInfo> extractConstructors(ClassElem classElement,
    List<FieldInfo> fields, IriTemplateInfo? iriTemplateInfo) {
  final iriPartNameByPropertyName =
      _getIriPartNameByPropertyName(iriTemplateInfo);

  final constructors = <ConstructorInfo>[];
  try {
    final fieldsByName = {for (final field in fields) field.name: field};

    for (final constructor in classElement.constructors) {
      final parameters = <ParameterInfo>[];

      for (final parameter in constructor.formalParameters) {
        // Find the corresponding field with @RdfProperty annotation, if it exists
        final fieldInfo = fieldsByName[parameter.name];

        parameters.add(ParameterInfo(
          name: parameter.name,
          type: typeToCode(parameter.type),
          isRequired: parameter.isRequired,
          isNamed: parameter.isNamed,
          isPositional: parameter.isPositional,
          isOptional: parameter.isOptional,
          propertyInfo: fieldInfo?.propertyInfo,
          isIriPart: iriPartNameByPropertyName.containsKey(parameter.name),
          iriPartName: iriPartNameByPropertyName[parameter.name],
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
    _log.severe('Error extracting constructors', e);
  }

  return constructors;
}

List<FieldInfo> extractFields(
    ValidationContext context, ClassElem classElement) {
  final gettersByName = {for (var g in classElement.getters) g.name: g};
  final settersByName = {for (var g in classElement.setters) g.name: g};
  final gettersOrSettersNames = <String>{
    ...gettersByName.keys,
    ...settersByName.keys,
  };
  final fieldNames =
      classElement.fields.where((f) => !f.isStatic).map((f) => f.name).toSet();

  _log.finest('Processing fields for class: ${classElement.name}');
  final virtualFields = gettersOrSettersNames
      .where((name) => !fieldNames.contains(name))
      .map((name) {
    final getter = gettersByName[name];
    final setter = settersByName[name];
    if (getter == null && setter == null) {
      // If neither getter nor setter exists, we skip it
      return null;
    }

    // FIXME: do we need postprocessing, if we have a RdfProperty annotation for example and automatically set include?
    // If only getter exists, we treat it as a field
    return fieldToFieldInfo(
      context,
      name: name,
      type: (getter?.type ?? setter?.type)!,
      isFinal: false,
      isLate: false,
      isSynthetic: false,
      annotations: [
        ...(getter?.annotations ?? const <ElemAnnotation>[]),
        ...(setter?.annotations ?? const <ElemAnnotation>[])
      ],
      isStatic: getter == null
          ? setter!.isStatic
          : (setter == null
              ? getter.isStatic
              : getter.isStatic && setter.isStatic),
    );
  }).nonNulls;
  final fields = classElement.fields.where((f) => !f.isStatic).map((f) {
    final getter = gettersByName[f.name];
    final setter = settersByName[f.name];

    return fieldToFieldInfo(context,
        name: f.name,
        type: f.type,
        isFinal: f.isFinal,
        isLate: f.isLate,
        isSynthetic: f.isSynthetic,
        annotations: [
          ...f.annotations,
          // Sometimes getters/setters are detected as fields, but strangely they have no metadata
          // so we add metadata from getter/setter if exists
          ...(getter?.annotations ?? const <ElemAnnotation>[]),
          ...(setter?.annotations ?? const <ElemAnnotation>[])
        ],
        isStatic: f.isStatic);
  });
  return [
    ...virtualFields,
    ...fields,
  ];
}

FieldInfo fieldToFieldInfo(ValidationContext context,
    {required String name,
    required DartType type,
    required Iterable<ElemAnnotation> annotations,
    required bool isStatic,
    required bool isFinal,
    required bool isLate,
    required bool isSynthetic}) {
  final mapEntry = extractMapEntryAnnotation(context, name, annotations);
  final mapKey = extractMapKeyAnnotation(annotations);
  final mapValue = extractMapValueAnnotation(annotations);

  final propertyInfo = PropertyProcessor.processFieldAlike(
    context,
    type: type,
    name: name,
    annotations: annotations,
    isStatic: isStatic,
    isFinal: isFinal,
    isLate: isLate,
    isSynthetic: isSynthetic,
    mapEntry: mapEntry,
  );
  final isNullable = type.isNullable;

  _log.finest('Annotations for field $name: $annotations');
  final isRdfValue = getAnnotation(annotations, 'RdfValue') != null;
  final isRdfLanguageTag = getAnnotation(annotations, 'RdfLanguageTag') != null;
  final providesInfo = extractProvidesAnnotation(
    name,
    annotations,
  );
  final iriPart = extractIriPartAnnotation(name, annotations);
  return FieldInfo(
      name: name,
      type: typeToCode(type),
      typeNonNull: typeToCode(type, enforceNonNull: true),
      isFinal: isFinal,
      isLate: isLate,
      isStatic: isStatic,
      isSynthetic: isSynthetic,
      propertyInfo: propertyInfo,
      isRequired: propertyInfo?.isRequired ?? !isNullable,
      isRdfLanguageTag: isRdfLanguageTag,
      isRdfValue: isRdfValue,
      provides: providesInfo,
      iriPart: iriPart,
      mapEntry: mapEntry,
      mapKey: mapKey,
      mapValue: mapValue);
}

ProvidesAnnotationInfo? extractProvidesAnnotation(
  String name,
  Iterable<ElemAnnotation> annotations,
) {
  final providesAnnotation = getAnnotation(annotations, 'RdfProvides');
  if (providesAnnotation == null) {
    return null;
  }
  final providesName = getFieldStringValue(providesAnnotation, 'name');
  return ProvidesAnnotationInfo(
    name: providesName ?? name,
    dartPropertyName: name,
  );
}

/// Extracts enum constants and their custom @RdfEnumValue annotations.
List<EnumValueInfo> extractEnumValues(
    ValidationContext context, EnumElem enumElement) {
  final enumValues = <EnumValueInfo>[];

  for (final constant in enumElement.constants) {
    final constantName = constant.name;
    final enumValueAnnotation =
        getAnnotation(constant.annotations, 'RdfEnumValue');

    String serializedValue;
    if (enumValueAnnotation != null) {
      // Use custom value from @RdfEnumValue
      final customValue = getFieldStringValue(enumValueAnnotation, 'value');
      if (customValue == null || customValue.isEmpty) {
        context.addError(
            'Custom value for enum constant $constantName cannot be empty');
        continue;
      }
      serializedValue = customValue;
    } else {
      // Use enum constant name as default
      serializedValue = constantName;
    }

    enumValues.add(EnumValueInfo(
      constantName: constantName,
      serializedValue: serializedValue,
    ));
  }

  return enumValues;
}

/// Information about RDF annotation on a type
class RdfTypeAnnotationInfo {
  final String annotationType; // 'RdfGlobalResource', 'RdfLocalResource', etc.
  final bool registerGlobally;
  final String mapperClassName;
  final String mapperImportPath;

  const RdfTypeAnnotationInfo({
    required this.annotationType,
    required this.registerGlobally,
    required this.mapperClassName,
    required this.mapperImportPath,
  });

  @override
  String toString() =>
      'RdfTypeAnnotationInfo(type: $annotationType, registerGlobally: $registerGlobally, '
      'mapper: $mapperClassName)';
}

/// Analyzes a Dart type to determine if it has RDF annotations and whether
/// a mapper should be inferred for it.
RdfTypeAnnotationInfo? analyzeTypeForRdfAnnotation(DartType type) {
  if (type.isNotInterfaceType) {
    return null;
  }

  final element = type.element;
  if (element is! AnnotatedElem) {
    // Not an annotated element, skip
    return null;
  }
  final annotations = (element as AnnotatedElem).annotations;

  // Check for RDF annotations
  final rdfAnnotations = [
    'RdfGlobalResource',
    'RdfLocalResource',
    'RdfIri',
    'RdfLiteral',
  ];

  for (final annotationType in rdfAnnotations) {
    final annotation = getAnnotation(annotations, annotationType);
    if (annotation != null) {
      final registerGlobally = isRegisterGlobally(annotation);

      // Generate mapper class name and import path
      final className = element.name;
      final mapperClassName = '${className}Mapper';

      // Determine import path based on the source library
      final sourceLibraryUri = element.libraryIdentifier!;

      String mapperImportPath;
      if (sourceLibraryUri.endsWith('.dart')) {
        // Convert from 'package:foo/to/source.dart' to 'package:foo/to/source.rdf_mapper.g.dart'
        mapperImportPath =
            '${sourceLibraryUri.substring(0, sourceLibraryUri.length - '.dart'.length)}.rdf_mapper.g.dart';
      } else {
        // Fallback for package imports or other schemes
        mapperImportPath = 'generated_mappers.dart';
      }

      return RdfTypeAnnotationInfo(
        annotationType: annotationType,
        registerGlobally: registerGlobally,
        mapperClassName: mapperClassName,
        mapperImportPath: mapperImportPath,
      );
    }
  }

  return null;
}
