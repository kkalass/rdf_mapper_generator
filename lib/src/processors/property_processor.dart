import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/exceptions.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Processes field elements to extract RDF property information.
class PropertyProcessor {
  /// Processes a field element to extract RDF property information.
  ///
  /// Returns a [PropertyInfo] if the field is annotated with `@RdfProperty`,
  /// otherwise returns `null`.
  static PropertyInfo? processField(
      ValidationContext context, FieldElement2 field) {
    final annotationObj = _getRdfPropertyAnnotation(field);
    if (annotationObj == null) {
      return null;
    }

    // Create an instance of RdfProperty from the annotation data
    final rdfProperty = _createRdfProperty(context, field, annotationObj);

    // Get the type system from the field's library
    final typeSystem = field.library2.typeSystem;

    // Check if the type is nullable
    final isNullable = field.type.isDartCoreNull ||
        (field.type is InterfaceType &&
            (field.type as InterfaceType).isDartCoreNull) ||
        typeSystem.isNullable(field.type);

    return PropertyInfo(
      name: field.name3!,
      type: field.type.getDisplayString(),
      annotation: rdfProperty,
      isRequired: !isNullable,
      isFinal: field.isFinal,
      isLate: field.isLate,
      isStatic: field.isStatic,
      isSynthetic: field.isSynthetic,
    );
  }

  static DartObject? _getRdfPropertyAnnotation(FieldElement2 field) {
    return getAnnotation(field.metadata2, 'RdfProperty');
  }

  static RdfPropertyInfo _createRdfProperty(
      ValidationContext context, FieldElement2 field, DartObject annotation) {
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
    final iri = _extractIriMapping(context, field, annotation);

    // Create and return the RdfProperty instance
    return RdfPropertyInfo(
      predicate,
      include: include,
      defaultValue: defaultValue,
      includeDefaultsInSerialization: includeDefaultsInSerialization,
      localResource: localResource,
      literal: literal,
      globalResource: globalResource,
      iri: iri,
      collection: collection,
    );
  }

  static IriMappingInfo? _extractIriMapping(
      ValidationContext context, FieldElement2 field, DartObject annotation) {
    // Check for named parameter 'iri'
    final iriMapping = getField(annotation, 'iri');
    if (isNull(iriMapping)) {
      return null;
    }
    // Check if it's an IriMapping
    final template = iriMapping!.getField('template')?.toStringValue();
    final mapper = getMapperRefInfo<IriTermMapper>(iriMapping);

    final templateInfo = template == null && mapper == null
        ? IriStrategyProcessor.processTemplate(context, '{+${field.name3!}}', [
            IriPartInfo(
                name: field.name3!,
                dartPropertyName: field.name3!,
                type: typeToCode(field.type),
                pos: 1,
                isMappedValue: true)
          ])!
        : template != null
            ? IriStrategyProcessor.processTemplate(context, template, [
                IriPartInfo(
                    name: field.name3!,
                    dartPropertyName: field.name3!,
                    type: typeToCode(field.type),
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
}
