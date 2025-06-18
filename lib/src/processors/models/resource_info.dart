import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_annotation_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';

/// Contains information about a class annotated with @RdfGlobalResource
sealed class MappableClassInfo {
  /// The name of the class
  Code get className;
}

/// Contains information about a class annotated with @RdfGlobalResource
class ResourceInfo implements MappableClassInfo {
  /// The name of the class
  final Code className;

  /// The RdfGlobalResource or RdfLocalResource annotation instance
  final RdfResourceInfo annotation;

  /// List of constructors in the class
  final List<ConstructorInfo> constructors;

  /// List of fields in the class
  final List<FieldInfo> fields;

  const ResourceInfo({
    required this.className,
    required this.annotation,
    required this.constructors,
    required this.fields,
  });

  bool get isGlobalResource => annotation is RdfGlobalResourceInfo;

  @override
  int get hashCode =>
      Object.hashAll([className, annotation, constructors, fields]);

  @override
  bool operator ==(Object other) {
    if (other is! ResourceInfo) {
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
  final IriTemplateInfo? templateInfo;
  final IriMapperType? iriMapperType;

  IriStrategyInfo({
    required super.mapper,
    required this.template,
    this.templateInfo,
    this.iriMapperType,
  });

  @override
  int get hashCode =>
      Object.hashAll([mapper, template, templateInfo, iriMapperType]);

  @override
  bool operator ==(Object other) {
    if (other is! IriStrategyInfo) {
      return false;
    }
    return mapper == other.mapper &&
        template == other.template &&
        templateInfo == other.templateInfo &&
        iriMapperType == other.iriMapperType;
  }

  @override
  String toString() {
    return 'IriStrategyInfo{'
        'mapper: $mapper, '
        'template: $template, '
        'templateInfo: $templateInfo, '
        'iriMapperType: $iriMapperType}';
  }
}

class VariableName {
  final String dartPropertyName;
  final String name;
  final bool canBeUri;

  VariableName({
    required this.dartPropertyName,
    required this.name,
    required this.canBeUri,
  });
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VariableName &&
        other.dartPropertyName == dartPropertyName &&
        other.name == name &&
        other.canBeUri == canBeUri;
  }

  @override
  int get hashCode => Object.hash(dartPropertyName, name, canBeUri);

  @override
  String toString() =>
      'VariableName(dartPropertyName: $dartPropertyName, name: $name, canBeUri: $canBeUri)';
}

class IriPartInfo {
  final String name;
  final String dartPropertyName;
  final Code type;
  final int pos;

  const IriPartInfo({
    required this.name,
    required this.dartPropertyName,
    required this.type,
    required this.pos,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriPartInfo &&
        other.name == name &&
        other.dartPropertyName == dartPropertyName &&
        other.type == type &&
        other.pos == pos;
  }

  @override
  int get hashCode => Object.hash(name, dartPropertyName, type, pos);

  @override
  String toString() =>
      'IriPartInfo(name: $name, dartPropertyName: $dartPropertyName, type: $type, pos: $pos)';
}

class IriMapperType {
  final Code type;
  final List<IriPartInfo> parts;

  const IriMapperType(this.type, this.parts);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriMapperType &&
        other.type == type &&
        other.parts.length == parts.length &&
        other.parts.every((part) => parts.contains(part));
  }

  @override
  int get hashCode => Object.hash(type, parts);

  @override
  String toString() => 'IriMapperType(type: $type, parts: $parts)';
}

/// Contains information about a processed IRI template.
class IriTemplateInfo {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableName> variableNames;
  Set<String> get variables => variableNames.map((e) => e.name).toSet();

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableName> propertyVariables;

  /// Variables that need to be provided from context.
  Set<String> get contextVariables =>
      contextVariableNames.map((e) => e.name).toSet();
  final Set<VariableName> contextVariableNames;

  /// Whether the template passed validation.
  final bool isValid;

  /// Validation error messages.
  final List<String> validationErrors;

  /// Warning messages about template configuration issues.
  final List<String> warnings;

  const IriTemplateInfo({
    required this.template,
    required Set<VariableName> variables,
    required this.propertyVariables,
    required Set<VariableName> contextVariables,
    required this.isValid,
    required this.validationErrors,
    this.warnings = const [],
  })  : variableNames = variables,
        contextVariableNames = contextVariables;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IriTemplateInfo) return false;

    return template == other.template &&
        variables.length == other.variables.length &&
        variables.difference(other.variables).isEmpty &&
        propertyVariables.length == other.propertyVariables.length &&
        propertyVariables.difference(other.propertyVariables).isEmpty &&
        contextVariables.length == other.contextVariables.length &&
        contextVariables.difference(other.contextVariables).isEmpty &&
        isValid == other.isValid &&
        validationErrors.length == other.validationErrors.length &&
        _listEquals(validationErrors, other.validationErrors) &&
        warnings.length == other.warnings.length &&
        _listEquals(warnings, other.warnings);
  }

  @override
  int get hashCode {
    return Object.hash(
      template,
      variables.length,
      propertyVariables.length,
      contextVariables.length,
      isValid,
      validationErrors.length,
      warnings.length,
    );
  }

  @override
  String toString() {
    return 'IriTemplateInfo('
        'template: $template, '
        'variables: $variables, '
        'propertyVariables: $propertyVariables, '
        'contextVariables: $contextVariables, '
        'isValid: $isValid, '
        'validationErrors: $validationErrors, '
        'warnings: $warnings, ';
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

sealed class RdfResourceInfo<T> extends BaseMappingAnnotationInfo<T> {
  final IriTermInfo? classIri;

  const RdfResourceInfo(
      {required this.classIri,
      required super.registerGlobally,
      required super.mapper});

  @override
  int get hashCode => Object.hashAll([classIri, registerGlobally, mapper]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfResourceInfo) {
      return false;
    }
    return classIri == other.classIri &&
        registerGlobally == other.registerGlobally &&
        mapper == other.mapper;
  }
}

class RdfGlobalResourceInfo extends RdfResourceInfo<GlobalResourceMapper> {
  final IriStrategyInfo? iri;
  const RdfGlobalResourceInfo(
      {required super.classIri,
      required this.iri,
      required super.registerGlobally,
      required super.mapper});

  @override
  int get hashCode => Object.hash(super.hashCode, iri);

  @override
  bool operator ==(Object other) {
    if (other is! RdfGlobalResourceInfo) {
      return false;
    }
    return super == other && iri == other.iri;
  }
}

class RdfLocalResourceInfo extends RdfResourceInfo<GlobalResourceMapper> {
  const RdfLocalResourceInfo(
      {required super.classIri,
      required super.registerGlobally,
      required super.mapper});

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! RdfLocalResourceInfo) {
      return false;
    }
    return super == other;
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

  /// The RDF property info associated with this parameter, if it maps to a field with @RdfProperty
  final PropertyInfo? propertyInfo;

  /// Whether this parameter is an IRI part
  final bool isIriPart;

  /// The name of the IRI part variable
  final String? iriPartName;

  const ParameterInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.isPositional,
    required this.isOptional,
    required this.propertyInfo,
    required this.isIriPart,
    required this.iriPartName,
  });

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        isRequired,
        isNamed,
        isPositional,
        isOptional,
        propertyInfo
      ]);

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
        isOptional == other.isOptional &&
        propertyInfo == other.propertyInfo;
  }

  @override
  String toString() {
    return 'ParameterInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isRequired: $isRequired,\n'
        '  isNamed: $isNamed,\n'
        '  isPositional: $isPositional,\n'
        '  isOptional: $isOptional,\n'
        '  propertyInfo: $propertyInfo\n'
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
  final PropertyInfo? propertyInfo;

  /// Whether this field is required (non-nullable)
  final bool isRequired;

  const FieldInfo({
    required this.name,
    required this.type,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
    this.propertyInfo,
    this.isRequired = false,
  });

  @override
  int get hashCode => Object.hashAll(
      [name, type, isFinal, isLate, isStatic, isSynthetic, propertyInfo]);

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
        propertyInfo == other.propertyInfo;
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
        '  propertyInfo: $propertyInfo,\n'
        '  isRequired: $isRequired\n'
        '}';
  }
}
