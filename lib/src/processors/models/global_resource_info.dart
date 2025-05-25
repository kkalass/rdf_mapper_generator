import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_annotation_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';

/// Contains information about a class annotated with @RdfGlobalResource
class GlobalResourceInfo {
  /// The name of the class
  final String className;

  /// The RdfGlobalResource annotation instance
  final RdfGlobalResourceInfo annotation;

  /// List of constructors in the class
  final List<ConstructorInfo> constructors;

  /// List of fields in the class
  final List<FieldInfo> fields;

  const GlobalResourceInfo({
    required this.className,
    required this.annotation,
    required this.constructors,
    required this.fields,
  });

  @override
  int get hashCode =>
      Object.hashAll([className, annotation, constructors, fields]);

  @override
  bool operator ==(Object other) {
    if (other is! GlobalResourceInfo) {
      return false;
    }
    return className == other.className &&
        annotation == other.annotation &&
        constructors == other.constructors &&
        fields == other.fields;
  }

  @override
  String toString() {
    return 'GlobalResourceInfo{\n'
        '  className: $className,\n'
        '  annotation: $annotation,\n'
        '  constructors: $constructors,\n'
        '  fields: $fields\n'
        '}';
  }
}

class IriStrategyInfo extends BaseMappingInfo<IriTermMapper> {
  final String? template;

  IriStrategyInfo({required super.mapper, required this.template});

  @override
  int get hashCode => Object.hashAll([mapper, template]);

  @override
  bool operator ==(Object other) {
    if (other is! IriStrategyInfo) {
      return false;
    }
    return mapper == other.mapper && template == other.template;
  }
}

class RdfGlobalResourceInfo
    extends BaseMappingAnnotationInfo<GlobalResourceMapper> {
  final IriTerm? classIri;
  final IriStrategyInfo? iri;
  const RdfGlobalResourceInfo(
      {required this.classIri,
      required this.iri,
      required super.registerGlobally,
      required super.mapper});

  @override
  int get hashCode => Object.hashAll([classIri, iri, registerGlobally, mapper]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfGlobalResourceInfo) {
      return false;
    }
    return classIri == other.classIri &&
        iri == other.iri &&
        registerGlobally == other.registerGlobally &&
        mapper == other.mapper;
  }
}

/// Information about a constructor
class ConstructorInfo {
  /// The name of the constructor (empty string for default constructor)
  final String name;

  /// Whether this is a factory constructor
  final bool isFactory;

  /// Whether this is a const constructor
  final bool isConst;

  /// Whether this is the default constructor
  final bool isDefaultConstructor;

  /// List of parameters for this constructor
  final List<ParameterInfo> parameters;

  const ConstructorInfo({
    required this.name,
    required this.isFactory,
    required this.isConst,
    required this.isDefaultConstructor,
    required this.parameters,
  });

  @override
  int get hashCode => Object.hashAll(
      [name, isFactory, isConst, isDefaultConstructor, parameters]);

  @override
  bool operator ==(Object other) {
    if (other is! ConstructorInfo) {
      return false;
    }
    return name == other.name &&
        isFactory == other.isFactory &&
        isConst == other.isConst &&
        isDefaultConstructor == other.isDefaultConstructor &&
        parameters == other.parameters;
  }

  @override
  String toString() {
    return 'ConstructorInfo{\n'
        '  name: $name,\n'
        '  isFactory: $isFactory,\n'
        '  isConst: $isConst,\n'
        '  isDefaultConstructor: $isDefaultConstructor,\n'
        '  parameters: $parameters\n'
        '}';
  }
}

/// Information about a parameter
class ParameterInfo {
  /// The name of the parameter
  final String name;

  /// The type of the parameter as a string
  final String type;

  /// Whether this parameter is required
  final bool isRequired;

  /// Whether this is a named parameter
  final bool isNamed;

  /// Whether this is a positional parameter
  final bool isPositional;

  /// Whether this parameter is optional
  final bool isOptional;

  const ParameterInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.isPositional,
    required this.isOptional,
  });

  @override
  int get hashCode => Object.hashAll(
      [name, type, isRequired, isNamed, isPositional, isOptional]);

  @override
  bool operator ==(Object other) {
    if (other is! ParameterInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        isRequired == other.isRequired &&
        isNamed == other.isNamed &&
        isPositional == other.isPositional &&
        isOptional == other.isOptional;
  }

  @override
  String toString() {
    return 'ParameterInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isRequired: $isRequired,\n'
        '  isNamed: $isNamed,\n'
        '  isPositional: $isPositional,\n'
        '  isOptional: $isOptional\n'
        '}';
  }
}

/// Information about a field
class FieldInfo {
  /// The name of the field
  final String name;

  /// The type of the field as a string
  final String type;

  /// Whether this field is final
  final bool isFinal;

  /// Whether this field is late-initialized
  final bool isLate;

  /// Whether this is a static field
  final bool isStatic;

  /// Whether this is a synthetic field
  final bool isSynthetic;

  /// The IRI of the RDF property associated with this field, if any
  final String? propertyIri;

  /// Whether this field is required (non-nullable)
  final bool isRequired;

  const FieldInfo({
    required this.name,
    required this.type,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
    this.propertyIri,
    this.isRequired = false,
  });

  @override
  int get hashCode => Object.hashAll(
      [name, type, isFinal, isLate, isStatic, isSynthetic, propertyIri]);

  @override
  bool operator ==(Object other) {
    if (other is! FieldInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        isFinal == other.isFinal &&
        isLate == other.isLate &&
        isStatic == other.isStatic &&
        isSynthetic == other.isSynthetic &&
        propertyIri == other.propertyIri;
  }

  @override
  String toString() {
    return 'FieldInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic,\n'
        '  propertyIri: $propertyIri,\n'
        '  isRequired: $isRequired\n'
        '}';
  }
}
