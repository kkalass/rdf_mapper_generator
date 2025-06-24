import 'package:analyzer/dart/constant/value.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';

class LocalResourceMappingInfo extends BaseMappingInfo {
  LocalResourceMappingInfo({required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! LocalResourceMappingInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'LocalResourceMappingInfo{mapper: $mapper}';
  }
}

class LiteralMappingInfo extends BaseMappingInfo {
  final String? language;

  final IriTermInfo? datatype;

  LiteralMappingInfo(
      {required this.language, required this.datatype, required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        language,
        datatype,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! LiteralMappingInfo) {
      return false;
    }
    return super == other &&
        language == other.language &&
        datatype == other.datatype;
  }

  @override
  String toString() {
    return 'LiteralMappingInfo{'
        'mapper: $mapper, '
        'language: $language, '
        'datatype: $datatype}';
  }
}

class GlobalResourceMappingInfo extends BaseMappingInfo {
  GlobalResourceMappingInfo({required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! GlobalResourceMappingInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'GlobalResourceMappingInfo{mapper: $mapper}';
  }
}

class IriMappingInfo extends BaseMappingInfo {
  final IriTemplateInfo? template;

  IriMappingInfo({required this.template, required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        template,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! IriMappingInfo) {
      return false;
    }
    return super == other && template == other.template;
  }

  @override
  String toString() {
    return 'IriMappingInfo{'
        'mapper: $mapper, '
        'template: $template}';
  }
}

class RdfPropertyInfo implements RdfAnnotation {
  final IriTermInfo predicate;

  final bool include;

  final DartObject? defaultValue;

  final bool includeDefaultsInSerialization;

  final IriMappingInfo? iri;

  final LocalResourceMappingInfo? localResource;

  final LiteralMappingInfo? literal;

  final GlobalResourceMappingInfo? globalResource;

  final RdfCollectionType collection;

  const RdfPropertyInfo(
    this.predicate, {
    required this.include,
    required this.defaultValue,
    required this.includeDefaultsInSerialization,
    required this.iri,
    required this.localResource,
    required this.literal,
    required this.globalResource,
    required this.collection,
  });

  @override
  int get hashCode => Object.hashAll([
        predicate,
        include,
        defaultValue,
        includeDefaultsInSerialization,
        iri,
        localResource,
        literal,
        globalResource,
        collection,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfPropertyInfo) {
      return false;
    }
    return predicate == other.predicate &&
        include == other.include &&
        defaultValue == other.defaultValue &&
        includeDefaultsInSerialization ==
            other.includeDefaultsInSerialization &&
        iri == other.iri &&
        localResource == other.localResource &&
        literal == other.literal &&
        globalResource == other.globalResource &&
        collection == other.collection;
  }

  @override
  String toString() {
    return 'RdfPropertyInfo{'
        'predicate: $predicate, '
        'include: $include, '
        'defaultValue: $defaultValue, '
        'includeDefaultsInSerialization: $includeDefaultsInSerialization, '
        'iri: $iri, '
        'localResource: $localResource, '
        'literal: $literal, '
        'globalResource: $globalResource, '
        'collection: $collection}';
  }
}

/// Contains information about a field annotated with `@RdfProperty`
class PropertyInfo {
  /// The name of the field
  final String name;

  /// The type of the field as a string
  final String type;

  /// The complete RdfProperty annotation instance
  final RdfPropertyInfo annotation;

  /// Whether this is a required field
  final bool isRequired;

  /// Whether this is a final field
  final bool isFinal;

  /// Whether this is a late-initialized field
  final bool isLate;

  /// Whether this is a static field
  final bool isStatic;

  /// Whether this is a synthetic field
  final bool isSynthetic;

  const PropertyInfo({
    required this.name,
    required this.type,
    required this.annotation,
    required this.isRequired,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
  });

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        annotation,
        isRequired,
        isFinal,
        isLate,
        isStatic,
        isSynthetic,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! PropertyInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        annotation == other.annotation &&
        isRequired == other.isRequired &&
        isFinal == other.isFinal &&
        isLate == other.isLate &&
        isStatic == other.isStatic &&
        isSynthetic == other.isSynthetic;
  }

  @override
  String toString() {
    return 'PropertyInfo{\n'
        '  name: $name,\n'
        '  annotation: $annotation,\n'
        '  type: $type,\n'
        '  isRequired: $isRequired,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic,\n'
        '}';
  }
}
