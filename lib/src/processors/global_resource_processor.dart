import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';

/// Processes class elements to extract RDF global resource information.
class GlobalResourceProcessor {
  /// Processes a class element to extract RDF global resource information.
  ///
  /// Returns a [MappableClassInfo] containing the processed information if the class is annotated
  /// with `@RdfGlobalResource`, otherwise returns `null`.
  static GlobalResourceInfo? processClass(ClassElement2 classElement,
      {LibsByClassName? libsByClassName}) {
    final annotation =
        getAnnotation(classElement.metadata2, 'RdfGlobalResource');
    if (annotation == null) {
      return null;
    }
    if (libsByClassName == null) {
      libsByClassName = LibsByClassName.create(classElement.library2);
    }

    final className = classElement.displayName;

    // Create the RdfGlobalResource instance from the annotation
    final rdfGlobalResource =
        _createRdfGlobalResource(annotation, classElement, libsByClassName);
    final iriTemplateInfo = rdfGlobalResource.iri?.templateInfo;
    final iriPartNameByPropertyName = Map<String, String>.fromIterable(
      iriTemplateInfo?.propertyVariables ?? const [],
      key: (pv) => pv.dartPropertyName,
      value: (pv) => pv.name,
    );
    final fields = _extractFields(classElement, libsByClassName);
    final constructors =
        _extractConstructors(classElement, fields, iriPartNameByPropertyName);

    return GlobalResourceInfo(
      className: className,
      annotation: rdfGlobalResource,
      constructors: constructors,
      fields: fields,
    );
  }

  static RdfGlobalResourceInfo _createRdfGlobalResource(DartObject annotation,
      ClassElement2 classElement, LibsByClassName libsByClassName) {
    try {
      // Get the classIri from the annotation
      final classIri =
          getIriTermInfo(getField(annotation, 'classIri'), libsByClassName);

      // Get the iriStrategy from the annotation
      final iriStrategy = _getIriStrategy(annotation, classElement);

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

  static IriStrategyInfo? _getIriStrategy(
      DartObject annotation, ClassElement2 classElement) {
    // Check if we have an iri field (for the standard constructor)
    final iriValue = getField(annotation, 'iri');
    if (iriValue == null || iriValue.isNull) {
      return null;
    }
    final template = getField(iriValue, 'template')?.toStringValue();
    final mapper = getMapperRefInfo<IriTermMapper>(iriValue);

    // Process template if it exists
    final templateInfo = template != null
        ? IriStrategyProcessor.processTemplate(template, classElement)
        : null;

    return IriStrategyInfo(
      mapper: mapper,
      template: template,
      templateInfo: templateInfo,
    );
  }

  static List<ConstructorInfo> _extractConstructors(ClassElement2 classElement,
      List<FieldInfo> fields, Map<String, String> iriPartNameByPropertyName) {
    final constructors = <ConstructorInfo>[];
    try {
      final fieldsByName = Map.fromIterable(fields, key: (field) => field.name);

      for (final constructor in classElement.constructors2) {
        final parameters = <ParameterInfo>[];

        for (final parameter in constructor.formalParameters) {
          // Find the corresponding field with @RdfProperty annotation, if it exists
          final fieldInfo = fieldsByName[parameter.name3!];

          parameters.add(ParameterInfo(
            name: parameter.name3!,
            type: parameter.type.getDisplayString(),
            isRequired: parameter.isRequired,
            isNamed: parameter.isNamed,
            isPositional: parameter.isPositional,
            isOptional: parameter.isOptional,
            propertyInfo: fieldInfo?.propertyInfo,
            isIriPart: iriPartNameByPropertyName.containsKey(parameter.name3!),
            iriPartName: iriPartNameByPropertyName[parameter.name3!],
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

  static List<FieldInfo> _extractFields(
      ClassElement2 classElement, LibsByClassName libsByClassName) {
    final fields = <FieldInfo>[];
    final typeSystem = classElement.library2.typeSystem;

    for (final field in classElement.fields2) {
      if (field.isStatic) continue;

      final propertyInfo = PropertyProcessor.processField(field,
          libsByClassName: libsByClassName);
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
        propertyInfo: propertyInfo,
        isRequired: propertyInfo?.isRequired ?? !isNullable,
      ));
    }

    return fields;
  }
}
