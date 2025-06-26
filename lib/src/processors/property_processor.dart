import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/exceptions.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/type_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Container for inferred mapping information
class _InferredMappings {
  final GlobalResourceMappingInfo? globalResource;
  final LocalResourceMappingInfo? localResource;
  final LiteralMappingInfo? literal;
  final IriMappingInfo? iri;

  const _InferredMappings({
    this.globalResource,
    this.localResource,
    this.literal,
    this.iri,
  });
}

/// Processes field elements to extract RDF property information.
class PropertyProcessor {
  /// Processes a field element to extract RDF property information.
  ///
  /// Returns a [PropertyInfo] if the field is annotated with `@RdfProperty`,
  /// otherwise returns `null`.
  static PropertyInfo? processField(
      ValidationContext context, FieldElement2 field) {
    return processFieldAlike(
      context,
      typeSystem: field.library2.typeSystem,
      name: field.name3!,
      annotations: field.metadata2.annotations,
      isFinal: field.isFinal,
      isLate: field.isLate,
      isStatic: field.isStatic,
      isSynthetic: field.isSynthetic,
      type: field.type,
    );
  }

  static PropertyInfo? processFieldAlike(ValidationContext context,
      {required TypeSystem typeSystem,
      required String name,
      required DartType type,
      required Iterable<ElementAnnotation> annotations,
      required bool isStatic,
      required bool isFinal,
      required bool isLate,
      required bool isSynthetic}) {
    final annotationObj = _getRdfPropertyAnnotation(annotations);
    if (annotationObj == null) {
      return null;
    }

    // Create an instance of RdfProperty from the annotation data
    final rdfProperty = _createRdfProperty(context, name, type, annotationObj);

    // Analyze collection information
    final collectionInfo = analyzeCollectionType(type, rdfProperty.collection);

    // Check if the type is nullable
    final isNullable = type.isDartCoreNull ||
        (type is InterfaceType && type.isDartCoreNull) ||
        typeSystem.isNullable(type);

    return PropertyInfo(
      name: name,
      type: typeToCode(type),
      annotation: rdfProperty,
      isRequired: !isNullable,
      isFinal: isFinal,
      isLate: isLate,
      isStatic: isStatic,
      isSynthetic: isSynthetic,
      collectionInfo: collectionInfo,
    );
  }

  /// Analyzes a property type to determine collection information
  static CollectionInfo analyzeCollectionType(
      DartType dartType, RdfCollectionType collectionAnnotation) {
    // If explicitly set to none, treat as single value
    if (collectionAnnotation == RdfCollectionType.none) {
      return const CollectionInfo(treatAsCollection: false);
    }

    // Check if it's a collection type
    if (dartType is InterfaceType) {
      final element = dartType.element3;
      final className = element.name3;

      // Check for List
      if (className == 'List' && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.list,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          treatAsCollection: collectionAnnotation == RdfCollectionType.auto,
        );
      }

      // Check for Set
      if (className == 'Set' && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.set,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          treatAsCollection: collectionAnnotation == RdfCollectionType.auto,
        );
      } // Check for Map
      if (className == 'Map' && dartType.typeArguments.length == 2) {
        final keyType = dartType.typeArguments[0];
        final valueType = dartType.typeArguments[1];

        return CollectionInfo(
          type: CollectionType.map,
          elementTypeCode:
              null, // We'll handle this specially in code generation
          keyTypeCode: typeToCode(keyType),
          valueTypeCode: typeToCode(valueType),
          treatAsCollection: collectionAnnotation == RdfCollectionType.auto,
        );
      }

      if (dartType.isDartCoreIterable && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.iterable,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          treatAsCollection: collectionAnnotation == RdfCollectionType.auto,
        );
      }
    }

    // Not a recognized collection type
    return const CollectionInfo(treatAsCollection: false);
  }

  static DartObject? _getRdfPropertyAnnotation(
      Iterable<ElementAnnotation> annotations) {
    return getAnnotation(annotations, 'RdfProperty');
  }

  static RdfPropertyInfo _createRdfProperty(ValidationContext context,
      String fieldName, DartType fieldType, DartObject annotation) {
    // Extract the predicate IRI
    final predicate = getIriTermInfo(getField(annotation, 'predicate'));
    if (predicate == null) {
      throw ParseException('RdfProperty must have a predicate');
    }
    final include = getField(annotation, 'include')?.toBoolValue() ?? true;
    final defaultValue = getField(annotation, 'defaultValue');
    final includeDefaultsInSerialization =
        getField(annotation, 'includeDefaultsInSerialization')?.toBoolValue() ??
            false;
    final localResource = _extractLocalResourceMapping(annotation);
    final literal = _extractLiteralMapping(annotation);
    final globalResource = _extractGlobalResourceMapping(annotation);
    final collection = getEnumFieldValue(annotation, 'collection',
        RdfCollectionType.values, RdfCollectionType.auto);
    // Extract IRI mapping if present
    final iri = _extractIriMapping(context, fieldName, fieldType, annotation);

    // Smart inference: if no explicit mapping is provided and the field type
    // has an RDF annotation with registerGlobally: false, infer the appropriate mapper
    final inferredMappings = _inferMappingsFromType(
        fieldType, localResource, literal, globalResource, iri);

    // Create and return the RdfProperty instance
    return RdfPropertyInfo(
      predicate,
      include: include,
      defaultValue: defaultValue,
      includeDefaultsInSerialization: includeDefaultsInSerialization,
      localResource: inferredMappings.localResource ?? localResource,
      literal: inferredMappings.literal ?? literal,
      globalResource: inferredMappings.globalResource ?? globalResource,
      iri: inferredMappings.iri ?? iri,
      collection: collection,
    );
  }

  static IriMappingInfo? _extractIriMapping(ValidationContext context,
      String fieldName, DartType fieldType, DartObject annotation) {
    // Check for named parameter 'iri'
    final iriMapping = getField(annotation, 'iri');
    if (isNull(iriMapping)) {
      return null;
    }
    // Check if it's an IriMapping
    final template = iriMapping!.getField('template')?.toStringValue();
    final mapper = getMapperRefInfo<IriTermMapper>(iriMapping);

    final templateInfo = template == null && mapper == null
        ? IriStrategyProcessor.processTemplate(context, '{+${fieldName}}', [
            IriPartInfo(
                name: fieldName,
                dartPropertyName: fieldName,
                type: typeToCode(fieldType),
                pos: 1,
                isMappedValue: true)
          ])!
        : template != null
            ? IriStrategyProcessor.processTemplate(context, template, [
                IriPartInfo(
                    name: fieldName,
                    dartPropertyName: fieldName,
                    type: typeToCode(fieldType),
                    pos: 1,
                    isMappedValue: true)
              ])!
            : null;
    return IriMappingInfo(template: templateInfo, mapper: mapper);
  }

  static LocalResourceMappingInfo? _extractLocalResourceMapping(
      DartObject annotation) {
    // Check for named parameter 'iri'
    final localResource = getField(annotation, 'localResource');
    if (isNull(localResource)) {
      return null;
    }
    // Check if it's an IriMapping
    final mapper = getMapperRefInfo<IriTermMapper>(localResource!);
    return LocalResourceMappingInfo(mapper: mapper);
  }

  static GlobalResourceMappingInfo? _extractGlobalResourceMapping(
      DartObject annotation) {
    // Check for named parameter 'iri'
    final globalResource = getField(annotation, 'globalResource');
    if (isNull(globalResource)) {
      return null;
    }
    // Check if it's an IriMapping
    final mapper = getMapperRefInfo<IriTermMapper>(globalResource!);
    return GlobalResourceMappingInfo(mapper: mapper);
  }

  static LiteralMappingInfo? _extractLiteralMapping(DartObject annotation) {
    // Check for named parameter 'iri'
    final literal = getField(annotation, 'literal');
    if (isNull(literal)) {
      return null;
    }
    // Check if it's an IriMapping
    final language = getField(literal!, 'language')?.toStringValue();
    final datatype = getIriTermInfo(getField(literal, 'datatype'));
    final mapper = getMapperRefInfo<IriTermMapper>(literal);
    return LiteralMappingInfo(
        language: language, datatype: datatype, mapper: mapper);
  }

  /// Infers appropriate mappings if no explicit mapping is provided
  /// and the field type has an RDF annotation with registerGlobally: false.
  static _InferredMappings _inferMappingsFromType(
    DartType fieldType,
    LocalResourceMappingInfo? existingLocalResource,
    LiteralMappingInfo? existingLiteral,
    GlobalResourceMappingInfo? existingGlobalResource,
    IriMappingInfo? existingIri,
  ) {
    // Only infer if no explicit mapping is already provided
    if (existingLocalResource != null ||
        existingLiteral != null ||
        existingGlobalResource != null ||
        existingIri != null) {
      return const _InferredMappings();
    }

    // Analyze the field type for RDF annotations
    final rdfAnnotationInfo = analyzeTypeForRdfAnnotation(fieldType);
    if (rdfAnnotationInfo == null) {
      return const _InferredMappings();
    }

    // Only infer for types with registerGlobally: false
    if (rdfAnnotationInfo.registerGlobally) {
      return const _InferredMappings();
    }
    final type = TypeInfo(
        name: Code.type(rdfAnnotationInfo.mapperClassName,
            importUri: rdfAnnotationInfo.mapperImportPath));
    // Create the appropriate mapper reference based on annotation type
    switch (rdfAnnotationInfo.annotationType) {
      case 'RdfGlobalResource':
        final mapperRef = MapperRefInfo<GlobalResourceMapper>(
          name: null,
          type: type, // We'll use the mapper class name directly
          instance: null,
        );
        return _InferredMappings(
          globalResource: GlobalResourceMappingInfo(mapper: mapperRef),
        );

      case 'RdfLocalResource':
        final mapperRef = MapperRefInfo<LocalResourceMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          localResource: LocalResourceMappingInfo(mapper: mapperRef),
        );

      case 'RdfLiteral':
        final mapperRef = MapperRefInfo<LiteralTermMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          literal: LiteralMappingInfo(
            language: null, // Default values since we're inferring
            datatype: null,
            mapper: mapperRef,
          ),
        );

      case 'RdfIri':
        final mapperRef = MapperRefInfo<IriTermMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          iri: IriMappingInfo(
            template: null, // Default template will be handled elsewhere
            mapper: mapperRef,
          ),
        );

      default:
        return const _InferredMappings();
    }
  }
}
