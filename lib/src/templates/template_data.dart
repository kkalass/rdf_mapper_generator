import 'package:rdf_mapper_generator/src/templates/util.dart';

/// Information about a mapper reference
class MapperRefData {
  /// The name of the mapper (for named mappers)
  final String? name;

  /// The type of the mapper implementation (for type-based mappers)
  final String? implementationType;

  /// The (interface) type of the mapper (for all mappers)
  final String type;

  /// Whether this is a named mapper
  final bool isNamed;

  /// Whether this is a type-based mapper
  final bool isTypeBased;

  /// Whether this is a direct instance
  final bool isInstance;

  final String? instanceInitializationCode;

  const MapperRefData({
    this.name,
    this.implementationType,
    required this.type,
    this.isNamed = false,
    this.isTypeBased = false,
    this.isInstance = false,
    this.instanceInitializationCode,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'implementationType': implementationType,
        'type': type,
        'isNamed': isNamed,
        'isTypeBased': isTypeBased,
        'isInstance': isInstance,
        'instanceInitializationCode': instanceInitializationCode,
      };
}

sealed class MappableClassMapperTemplateData {
  /// Required imports for the generated file
  List<ImportData> get imports;

  Map<String, dynamic> toMap();
}

// FIXME: implement properly, this is for @RdfGlobalResource where
// a custom mapper is used via one of the constructors
class GlobalResourceMapperCustomTemplateData
    implements MappableClassMapperTemplateData {
  /// Required imports for the generated file
  final List<ImportData> imports;

  const GlobalResourceMapperCustomTemplateData({
    required this.imports,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'imports': imports.map((i) => i.toMap()).toList(),
    };
  }
}

/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class GlobalResourceMapperTemplateData
    implements MappableClassMapperTemplateData {
  /// Required imports for the generated file
  final List<ImportData> imports;

  /// The name of the Dart class being mapped
  final String className;

  /// The name of the generated mapper class
  final String mapperClassName;

  /// The type IRI expression (e.g., 'SchemaBook.classIri')
  final String? typeIri;

  /// IRI strategy information
  final IriStrategyData iriStrategy;

  /// List of parameters for this constructor
  final List<ParameterData> constructorParameters;

  /// Property mapping information
  final List<PropertyData> properties = const [];

  /// Context variable providers needed for IRI generation
  final List<ContextProviderData> contextProviders;

  final bool needsReader;
  const GlobalResourceMapperTemplateData({
    required this.imports,
    required this.className,
    required this.mapperClassName,
    required this.typeIri,
    required this.iriStrategy,
    required this.contextProviders,
    required this.constructorParameters,
    required this.needsReader,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'imports': imports.map((i) => i.toMap()).toList(),
      'className': className,
      'mapperClassName': mapperClassName,
      'typeIri': typeIri,
      'hasTypeIri': typeIri != null,
      'iriStrategy': iriStrategy.toMap(),
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'properties': properties.map((p) => p.toMap()).toList(),
      'contextProviders':
          toMustacheList(contextProviders.map((p) => p.toMap()).toList()),
      'hasContextProviders': contextProviders.isNotEmpty,
      'hasMapperConstructorParameters':
          iriStrategy.hasMapper || contextProviders.isNotEmpty,
      'needsReader': needsReader,
    };
  }
}

/// Template data for the entire generated file.
///
/// This contains the file header, all imports, and all mapper classes.
class FileTemplateData {
  /// Header information with source path and generation timestamp
  final FileHeaderData header;

  /// All imports required for the file
  final List<ImportData> imports;

  /// All generated mapper classes
  final List<MapperData> mappers;

  const FileTemplateData({
    required this.header,
    required this.imports,
    required this.mappers,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'header': header.toMap(),
      'imports': imports.map((i) => i.toMap()).toList(),
      'mappers': mappers.map((m) => m.toMap()).toList(),
    };
  }
}

/// Template data for file header information.
class FileHeaderData {
  final String sourcePath;
  final String generatedOn;

  const FileHeaderData({
    required this.sourcePath,
    required this.generatedOn,
  });

  Map<String, dynamic> toMap() => {
        'sourcePath': sourcePath,
        'generatedOn': generatedOn,
      };
}

/// Template data for a single mapper class.
class MapperData {
  final MappableClassMapperTemplateData mapperData;

  const MapperData(this.mapperData);

  Map<String, dynamic> toMap() {
    return {
      '__type__': mapperData.runtimeType.toString(),
      ...mapperData.toMap(),
    };
  }
}

/// Data for import statements
class ImportData {
  final String import;

  const ImportData(this.import);

  Map<String, dynamic> toMap() => {'import': import};
}

/// Data for context variable providers required by the mapper
class ContextProviderData {
  /// The name of the context variable
  final String variableName;

  /// The name of the private field that stores the provider
  final String privateFieldName;

  /// The name of the constructor parameter
  final String parameterName;

  /// The placeholder pattern to replace in IRI templates (e.g., '{baseUri}')
  final String placeholder;

  const ContextProviderData({
    required this.variableName,
    required this.privateFieldName,
    required this.parameterName,
    required this.placeholder,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'privateFieldName': privateFieldName,
        'parameterName': parameterName,
        'placeholder': placeholder,
      };
}

class VariableNameData {
  final String variableName;
  final String placeholder;

  const VariableNameData({
    required this.variableName,
    required this.placeholder,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'placeholder': placeholder,
      };
}

class IriTemplateData {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameData> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameData> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<VariableNameData> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  const IriTemplateData({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
  });

  Map<String, dynamic> toMap() {
    return {
      'template': template,
      'variables': toMustacheList(variables.map((v) => v.toMap()).toList()),
      'propertyVariables':
          toMustacheList(propertyVariables.map((p) => p.toMap()).toList()),
      'contextVariables':
          toMustacheList(contextVariables.map((c) => c.toMap()).toList()),
      'regexPattern': regexPattern,
    };
  }
}

class IriPartData {
  final String name;
  final String dartPropertyName;

  const IriPartData({
    required this.name,
    required this.dartPropertyName,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartPropertyName': dartPropertyName,
      };
}

/// Data for IRI strategy
class IriStrategyData {
  final IriTemplateData? template;
  final MapperRefData? mapper;
  final bool hasMapper;
  final List<IriPartData> iriMapperParts;

  const IriStrategyData({
    this.template,
    this.mapper,
    this.hasMapper = false,
    required this.iriMapperParts,
  });

  bool get hasTemplate => template != null;

  Map<String, dynamic> toMap() => {
        'template': template?.toMap(),
        'hasTemplate': hasTemplate,
        'mapper': mapper?.toMap(),
        'hasMapper': hasMapper,
        'iriMapperParts':
            toMustacheList(iriMapperParts.map((p) => p.toMap()).toList()),
        'hasIriMapperParts': iriMapperParts.isNotEmpty,
      };
}

/// Data for constructor parameters
class ParameterData {
  final String name;
  final String dartType;
  final bool isRequired;
  final bool isIriPart;
  final bool isRdfProperty;
  final bool isNamed;
  final String? iriPartName;
  final String? predicate;
  final String? defaultValue;
  final bool hasDefaultValue;

  const ParameterData({
    required this.name,
    required this.dartType,
    required this.isRequired,
    required this.isIriPart,
    required this.isRdfProperty,
    required this.isNamed,
    required this.iriPartName,
    required this.predicate,
    required this.defaultValue,
    required this.hasDefaultValue,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartType': dartType,
        // if default value is provided, then it is not required
        'isRequired': isRequired && !hasDefaultValue,
        'isIriPart': isIriPart && !isRdfProperty,
        'isRdfProperty': isRdfProperty,
        'isNamed': isNamed,
        'iriPartName': iriPartName,
        'predicate': predicate,
        'defaultValue': defaultValue,
        'hasDefaultValue': hasDefaultValue,
      };
}

/// Data for RDF properties
class PropertyData {
  final String propertyName;
  final String dartType;
  final bool isRequired;
  final bool isRdfProperty;
  final String? predicate;

  const PropertyData({
    required this.propertyName,
    required this.dartType,
    required this.isRequired,
    required this.isRdfProperty,
    this.predicate,
  });

  Map<String, dynamic> toMap() => {
        'propertyName': propertyName,
        'dartType': dartType,
        'isRequired': isRequired,
        'isRdfProperty': isRdfProperty,
        'predicate': predicate,
      };
}
