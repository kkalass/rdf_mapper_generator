import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:logging/logging.dart';
import 'package:rdf_core/rdf_core.dart';
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
    Iterable<ElementAnnotation> annotations, String annotationName) {
  try {
    // Get metadata from the class element
    ;
    for (final elementAnnotation in annotations) {
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
    _log.severe('Error extracting constructors', e);
  }

  return constructors;
}

List<FieldInfo> extractFields(
    ValidationContext context, ClassElement2 classElement) {
  final typeSystem = classElement.library2.typeSystem;
  final gettersByName = {for (var g in classElement.getters2) g.name3!: g};
  final settersByName = {for (var g in classElement.setters2) g.name3!: g};
  final gettersOrSettersNames = {
    ...gettersByName.keys,
    ...settersByName.keys,
  };
  final fieldNames = classElement.fields2
      .where((f) => !f.isStatic)
      .map((f) => f.name3!)
      .toSet();

  _log.finest('Processing fields for class: ${classElement.name3}');
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
      typeSystem: typeSystem,
      name: name,
      type: (getter?.type ?? setter?.type)!,
      isFinal: false,
      isLate: false,
      isSynthetic: false,
      annotations: [
        ...(getter?.metadata2.annotations ?? const <ElementAnnotation>[]),
        ...(setter?.metadata2.annotations ?? const <ElementAnnotation>[])
      ],
      isStatic: getter == null
          ? setter!.isStatic
          : (setter == null
              ? getter.isStatic
              : getter.isStatic && setter.isStatic),
    );
  }).nonNulls;
  final fields = classElement.fields2.where((f) => !f.isStatic).map((f) {
    final getter = gettersByName[f.name3!];
    final setter = settersByName[f.name3!];

    return fieldToFieldInfo(context,
        typeSystem: typeSystem,
        name: f.name3!,
        type: f.type,
        isFinal: f.isFinal,
        isLate: f.isLate,
        isSynthetic: f.isSynthetic,
        annotations: [
          ...f.metadata2.annotations,
          // Sometimes getters/setters are detected as fields, but strangely they have no metadata
          // so we add metadata from getter/setter if exists
          ...(getter?.metadata2.annotations ?? const <ElementAnnotation>[]),
          ...(setter?.metadata2.annotations ?? const <ElementAnnotation>[])
        ],
        isStatic: f.isStatic);
  });
  return [
    ...virtualFields,
    ...fields,
  ];
}

FieldInfo fieldToFieldInfo(ValidationContext context,
    {required TypeSystem typeSystem,
    required String name,
    required DartType type,
    required Iterable<ElementAnnotation> annotations,
    required bool isStatic,
    required bool isFinal,
    required bool isLate,
    required bool isSynthetic}) {
  final propertyInfo = PropertyProcessor.processFieldAlike(context,
      type: type,
      typeSystem: typeSystem,
      name: name,
      annotations: annotations,
      isStatic: isStatic,
      isFinal: isFinal,
      isLate: isLate,
      isSynthetic: isSynthetic);
  final isNullable = type.isDartCoreNull ||
      (type is InterfaceType && type.isDartCoreNull) ||
      typeSystem.isNullable(type);

  _log.finest('Annotations for field $name: $annotations');
  final isRdfValue = getAnnotation(annotations, 'RdfValue') != null;
  final isRdfLanguageTag = getAnnotation(annotations, 'RdfLanguageTag') != null;
  final providesAnnotation = getAnnotation(annotations, 'RdfProvides');
  final providesName = providesAnnotation?.getField('name')?.toStringValue();
  return FieldInfo(
    name: name,
    type: typeToCode(type),
    isFinal: isFinal,
    isLate: isLate,
    isStatic: isStatic,
    isSynthetic: isSynthetic,
    propertyInfo: propertyInfo,
    isRequired: propertyInfo?.isRequired ?? !isNullable,
    isRdfLanguageTag: isRdfLanguageTag,
    isRdfValue: isRdfValue,
    provides: providesAnnotation != null
        ? ProvidesInfo(
            name: providesName ?? name,
            dartPropertyName: name,
          )
        : null,
  );
}

/// Extracts enum constants and their custom @RdfEnumValue annotations.
List<EnumValueInfo> extractEnumValues(
    ValidationContext context, EnumElement2 enumElement) {
  final enumValues = <EnumValueInfo>[];

  for (final constant in enumElement.constants2) {
    final constantName = constant.name3!;
    final enumValueAnnotation =
        getAnnotation(constant.metadata2.annotations, 'RdfEnumValue');

    String serializedValue;
    if (enumValueAnnotation != null) {
      // Use custom value from @RdfEnumValue
      final customValue =
          getField(enumValueAnnotation, 'value')?.toStringValue();
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
