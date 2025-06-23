import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

/// Information about a mapper reference
class MapperRefData {
  /// The name of the mapper (for named mappers)
  final String? name;

  /// The type of the mapper implementation (for type-based mappers)
  final Code? implementationType;

  /// The (interface) type of the mapper (for all mappers)
  final Code type;

  /// Whether this is a named mapper
  final bool isNamed;

  /// Whether this is a type-based mapper
  final bool isTypeBased;

  /// Whether this is a direct instance
  final bool isInstance;

  final Code? instanceInitializationCode;

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
        'implementationType': implementationType?.toMap(),
        'type': type.toMap(),
        'isNamed': isNamed,
        'isTypeBased': isTypeBased,
        'isInstance': isInstance,
        'instanceInitializationCode': instanceInitializationCode?.toMap(),
      };
}

sealed class MappableClassMapperTemplateData {
  Map<String, dynamic> toMap();
}

class CustomMapperTemplateData implements MappableClassMapperTemplateData {
  final String? customMapperName;
  final Code mapperInterfaceType;
  final Code className;
  final Code? customMapperType;
  final Code? customMapperInstance;
  final bool registerGlobally;

  const CustomMapperTemplateData({
    required this.className,
    required this.mapperInterfaceType,
    required this.customMapperName,
    required this.customMapperType,
    required this.customMapperInstance,
    required this.registerGlobally,
  }) : assert(
          customMapperName != null ||
              customMapperType != null ||
              customMapperInstance != null,
          'At least one of customMapperName, customMapperType or customMapperInstance must be provided',
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperInterfaceType': mapperInterfaceType.toMap(),
      'customMapperName': customMapperName,
      'customMapperType': customMapperType?.toMap(),
      'customMapperInstance': customMapperInstance?.toMap(),
      'hasCustomMapperName': customMapperName != null,
      'hasCustomMapperType': customMapperType != null,
      'hasCustomMapperInstance': customMapperInstance != null,
      'registerGlobally': registerGlobally,
    };
  }
}

/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class ResourceMapperTemplateData implements MappableClassMapperTemplateData {
  /// The name of the Dart class being mapped
  final Code className;

  /// The name of the generated mapper class
  final Code mapperClassName;

  final Code mapperInterfaceName;
  final Code termClass;

  /// The type IRI expression (e.g., 'SchemaBook.classIri')
  final Code? typeIri;

  /// IRI strategy information
  final IriData? iriStrategy;

  /// List of parameters for this constructor
  final List<ParameterData> constructorParameters;
  final List<ParameterData> nonConstructorFields;

  /// Property mapping information
  final List<PropertyData> properties;

  /// Context variable providers needed for IRI generation
  final List<ContextProviderData> contextProviders;

  final bool needsReader;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  const ResourceMapperTemplateData({
    required Code className,
    required Code mapperClassName,
    required this.mapperInterfaceName,
    required this.termClass,
    required Code? typeIri,
    required IriData? iriStrategy,
    required List<ContextProviderData> contextProviders,
    required List<ParameterData> constructorParameters,
    required bool needsReader,
    required bool registerGlobally,
    required List<PropertyData> properties,
    required List<ParameterData> nonConstructorFields,
  })  : className = className,
        mapperClassName = mapperClassName,
        typeIri = typeIri,
        iriStrategy = iriStrategy,
        contextProviders = contextProviders,
        constructorParameters = constructorParameters,
        nonConstructorFields = nonConstructorFields,
        needsReader = needsReader,
        registerGlobally = registerGlobally,
        properties = properties;

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'termClass': termClass.toMap(),
      'typeIri': typeIri?.toMap(),
      'hasTypeIri': typeIri != null,
      'hasIriStrategy': iriStrategy != null,
      'hasIriStrategyMapper': iriStrategy?.hasMapper ?? false,
      'iriStrategy': iriStrategy?.toMap(),
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'nonConstructorFields':
          toMustacheList(nonConstructorFields.map((p) => p.toMap()).toList()),
      'constructorParametersOrOtherFields': toMustacheList([
        ...constructorParameters,
        ...nonConstructorFields
      ].map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': nonConstructorFields.isNotEmpty,
      'properties': properties.map((p) => p.toMap()).toList(),
      'contextProviders':
          toMustacheList(contextProviders.map((p) => p.toMap()).toList()),
      'hasContextProviders': contextProviders.isNotEmpty,
      'hasMapperConstructorParameters':
          (iriStrategy?.hasMapper ?? false) || contextProviders.isNotEmpty,
      'needsReader': needsReader,
      'registerGlobally': registerGlobally,
    };
  }
}

class LiteralMapperTemplateData implements MappableClassMapperTemplateData {
  static final rdfLanguageDatatype = Code.combine([
    Code.type('Rdf', importUri: importRdfVocab),
    Code.value('.langString')
  ]).toMap();

  /// The name of the Dart class being mapped
  final Code className;

  /// The name of the generated mapper class
  final Code mapperClassName;

  final Code mapperInterfaceName;

  /// List of parameters for this constructor
  final List<ParameterData> constructorParameters;

  /// List of non-constructor fields that are RDF value or language tag fields
  final List<ParameterData> nonConstructorFields;

  /// Property mapping information
  final List<PropertyData> properties;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  final Code? datatype;
  final String? toLiteralTermMethod;
  final String? fromLiteralTermMethod;
  final ParameterData? rdfValue;
  final ParameterData? rdfLanguageTag;

  const LiteralMapperTemplateData({
    required Code className,
    required Code mapperClassName,
    required this.mapperInterfaceName,
    required this.datatype,
    required this.toLiteralTermMethod,
    required this.fromLiteralTermMethod,
    required this.rdfValue,
    required this.rdfLanguageTag,
    required List<ParameterData> constructorParameters,
    required List<ParameterData> nonConstructorFields,
    required bool registerGlobally,
    required List<PropertyData> properties,
  })  : className = className,
        mapperClassName = mapperClassName,
        constructorParameters = constructorParameters,
        nonConstructorFields = nonConstructorFields,
        registerGlobally = registerGlobally,
        properties = properties;

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'datatype': datatype?.toMap(),
      'toLiteralTermMethod': toLiteralTermMethod,
      'fromLiteralTermMethod': fromLiteralTermMethod,
      'hasDatatype': datatype != null,
      'hasMethods':
          toLiteralTermMethod != null && fromLiteralTermMethod != null,
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'nonConstructorFields':
          toMustacheList(nonConstructorFields.map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': nonConstructorFields.isNotEmpty,
      'constructorParametersOrOtherFields': toMustacheList([
        ...constructorParameters,
        ...nonConstructorFields
      ].map((p) => p.toMap()).toList()),
      'properties': properties.map((p) => p.toMap()).toList(),
      'registerGlobally': registerGlobally,
      'rdfValue': rdfValue?.toMap(),
      'hasRdfValue': rdfValue != null,
      'rdfLanguageTag': rdfLanguageTag?.toMap(),
      'hasRdfLanguageTag': rdfLanguageTag != null,
      'rdfLanguageDatatype': rdfLanguageDatatype,
      'hasCustomDatatype': datatype != null || rdfLanguageTag != null,
    };
  }
}

class IriMapperTemplateData implements MappableClassMapperTemplateData {
  /// The name of the Dart class being mapped
  final Code className;

  /// The name of the generated mapper class
  final Code mapperClassName;

  final Code mapperInterfaceName;

  /// IRI strategy information
  final IriData iriStrategy;

  /// List of parameters for this constructor
  final List<ParameterData> constructorParameters;

  /// List of non-constructor fields that are IRI parts
  final List<ParameterData> nonConstructorFields;

  /// Property mapping information
  final List<PropertyData> properties;

  /// Context variable providers needed for IRI generation
  final List<ContextProviderData> contextProviders;

  final bool needsReader;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  const IriMapperTemplateData({
    required Code className,
    required Code mapperClassName,
    required this.mapperInterfaceName,
    required IriData iriStrategy,
    required List<ContextProviderData> contextProviders,
    required List<ParameterData> constructorParameters,
    required List<ParameterData> nonConstructorFields,
    required bool needsReader,
    required bool registerGlobally,
    required List<PropertyData> properties,
  })  : className = className,
        mapperClassName = mapperClassName,
        iriStrategy = iriStrategy,
        contextProviders = contextProviders,
        constructorParameters = constructorParameters,
        nonConstructorFields = nonConstructorFields,
        needsReader = needsReader,
        registerGlobally = registerGlobally,
        properties = properties;

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'iriStrategy': iriStrategy.toMap(),
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'nonConstructorFields':
          toMustacheList(nonConstructorFields.map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': nonConstructorFields.isNotEmpty,
      'constructorParametersOrOtherFields': toMustacheList([
        ...constructorParameters,
        ...nonConstructorFields
      ].map((p) => p.toMap()).toList()),
      'properties': properties.map((p) => p.toMap()).toList(),
      'contextProviders':
          toMustacheList(contextProviders.map((p) => p.toMap()).toList()),
      'hasContextProviders': contextProviders.isNotEmpty,
      'needsReader': needsReader,
      'registerGlobally': registerGlobally,
    };
  }
}

/// Template data for the entire generated file.
///
/// This contains the file header, all imports, and all mapper classes.
class FileTemplateData {
  /// Header information with source path and generation timestamp
  final FileHeaderData header;

  final BroaderImports broaderImports;

  final Map<String, String> originalImports;

  /// All generated mapper classes
  final List<MapperData> mappers;

  const FileTemplateData({
    required this.header,
    required this.broaderImports,
    required this.originalImports,
    required this.mappers,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'header': header.toMap(),
      'broaderImports': broaderImports.toMap(),
      'originalImports': originalImports,
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
  final bool isRdfProperty;

  const IriPartData({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartPropertyName': dartPropertyName,
        'isRdfProperty': isRdfProperty,
      };
}

/// Data for IRI strategy
class IriData {
  final IriTemplateData? template;
  final MapperRefData? mapper;
  final bool hasMapper;
  final List<IriPartData> iriMapperParts;

  const IriData({
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
        'hasNonRdfPropertyIriParts': iriMapperParts
            .any((p) => !p.isRdfProperty && p.dartPropertyName.isNotEmpty),
      };
}

/// Data for constructor parameters
class ParameterData {
  final String name;
  final Code dartType;
  final bool isRequired;
  final bool isIriPart;
  final bool isRdfProperty;
  final bool isNamed;
  final String? iriPartName;
  final Code? predicate;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
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
    required this.isRdfValue,
    required this.isRdfLanguageTag,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartType': dartType.toMap(),
        // if default value is provided, then it is not required
        'isRequired': isRequired && !hasDefaultValue,
        'isIriPart': isIriPart && !isRdfProperty,
        'isRdfProperty': isRdfProperty,
        'isNamed': isNamed,
        'iriPartName': iriPartName,
        'predicate': predicate?.toMap(),
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': hasDefaultValue,
        'isRdfValue': isRdfValue,
        'isRdfLanguageTag': isRdfLanguageTag,
      };
}

/// Data for RDF properties
class PropertyData {
  final String propertyName;
  final bool isRequired;
  final bool isRdfProperty;
  final Code? predicate;

  const PropertyData({
    required this.propertyName,
    required this.isRequired,
    required this.isRdfProperty,
    this.predicate,
  });

  Map<String, dynamic> toMap() => {
        'propertyName': propertyName,
        'isRequired': isRequired,
        'isRdfProperty': isRdfProperty,
        'predicate': predicate?.toMap(),
      };
}
