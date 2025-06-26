import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

/// Information about a mapper reference
class MapperRefData {
  /// The name of the mapper (for named mappers)
  final String? name;

  /// The (interface) type of the mapper (for all mappers)
  final Code type;

  /// Whether this is a named mapper
  final bool isNamed;

  /// Whether this is a type-based mapper
  final bool isTypeBased;

  /// Whether this is a direct instance
  final bool isInstance;

  final ResolvableInstantiationCodeData? instanceInitializationCode;

  const MapperRefData({
    this.name,
    required this.type,
    this.isNamed = false,
    this.isTypeBased = false,
    this.isInstance = false,
    this.instanceInitializationCode,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.toMap(),
        'isNamed': isNamed,
        'isTypeBased': isTypeBased,
        'isInstance': isInstance,
        'instanceInitializationCode': instanceInitializationCode?.toMap(),
      };
}

class UnresolvedInstantiationCodeData {
  final List<ResolvableInstantiationCodeData> unresolved = [];

  add(ResolvableInstantiationCodeData data) {
    if (unresolved.contains(data)) {
      throw StateError(
          'ResolvableInstantiationCodeData is already added to unresolved list');
    }
    unresolved.add(data);
  }
}

class ResolvableInstantiationCodeData {
  final Code? mapperClassName;
  late final Code _resolvedCode;
  bool _isResolved = false;

  ResolvableInstantiationCodeData._(this.mapperClassName);

  factory ResolvableInstantiationCodeData(
      Code mapperClassName, UnresolvedInstantiationCodeData unresolved) {
    final r = ResolvableInstantiationCodeData._(mapperClassName);
    unresolved.add(r);
    return r;
  }

  ResolvableInstantiationCodeData.resolved(Code resolved)
      : mapperClassName = null,
        _resolvedCode = resolved;

  bool get isResolved => _isResolved;

  resolve(List<ConstructorParameterData> constructorParameters,
      {bool constContext = false}) {
    if (mapperClassName == null) {
      throw StateError(
          'MapperTypeInfoData is already resolved or has no mapper class name');
    }
    _resolvedCode = Code.combine([
      if (constContext) Code.literal(' const '),
      mapperClassName!,
      Code.literal('('),
      Code.combine(
          constructorParameters
              .map((p) => Code.combine([
                    Code.literal(p.parameterName),
                    Code.literal(': '),
                    Code.literal(p.parameterName)
                  ]))
              .toList(),
          separator: ', '),
      Code.literal(')')
    ]);
    _isResolved = true;
  }

  Map<String, dynamic> toMap() => _resolvedCode.toMap();
}

sealed class MappableClassMapperTemplateData {
  Map<String, dynamic> toMap();
  const MappableClassMapperTemplateData();
}

sealed class GeneratedMapperTemplateData
    extends MappableClassMapperTemplateData {
  /// The name of the Dart class being mapped
  final Code className;

  /// The name of the generated mapper class
  final Code mapperClassName;

  /// The name of the mapper interface
  final Code mapperInterfaceName;

  /// Context variable providers needed for IRI generation
  final List<ContextProviderData> contextProviders;

  const GeneratedMapperTemplateData({
    required this.className,
    required this.mapperClassName,
    required this.mapperInterfaceName,
    required this.contextProviders,
  });

  /// Most mappers will only have context providers as constructor parameters,
  /// but some may have additional parameters.
  List<ConstructorParameterData>
      get mapperConstructorParameters => contextProviders
          .map((p) => ConstructorParameterData(
              type: contextProviderType,
              parameterName: p.variableName,
              fieldName: p.privateFieldName,
              defaultValue: null,
              isLate: false,
              isField: p.isField))
          .toList();
}

class CustomMapperTemplateData implements MappableClassMapperTemplateData {
  final String? customMapperName;
  final Code mapperInterfaceType;
  final Code className;
  final bool isTypeBased;
  final ResolvableInstantiationCodeData? customMapperInstance;
  final bool registerGlobally;

  const CustomMapperTemplateData({
    required this.className,
    required this.mapperInterfaceType,
    required this.customMapperName,
    required this.isTypeBased,
    required this.customMapperInstance,
    required this.registerGlobally,
  }) : assert(
          customMapperName != null || customMapperInstance != null,
          'At least one of customMapperName or customMapperInstance must be provided',
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperInterfaceType': mapperInterfaceType.toMap(),
      'customMapperName': customMapperName,
      'customMapperInstance': customMapperInstance?.toMap(),
      'hasCustomMapperName': customMapperName != null,
      'isTypeBased': isTypeBased,
      'hasCustomMapperInstance': customMapperInstance != null,
      'registerGlobally': registerGlobally,
    };
  }
}

/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class ResourceMapperTemplateData extends GeneratedMapperTemplateData {
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
  final List<ConstructorParameterData> mapperConstructorParameters;
  final bool needsReader;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  const ResourceMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required this.termClass,
    required Code? typeIri,
    required IriData? iriStrategy,
    required super.contextProviders,
    required List<ParameterData> constructorParameters,
    required bool needsReader,
    required bool registerGlobally,
    required List<PropertyData> properties,
    required List<ParameterData> nonConstructorFields,
    required this.mapperConstructorParameters,
  })  : typeIri = typeIri,
        iriStrategy = iriStrategy,
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
      'mapperConstructorParameters': toMustacheList(
          mapperConstructorParameters.map((p) => p.toMap()).toList()),
      'hasLateMapperConstructorParameters':
          mapperConstructorParameters.where((p) => p.isLate).isNotEmpty,
      'mapperConstructorParameterAssignments': toMustacheList(
          mapperConstructorParameters
              .where((p) => p.needsAssignment && p.isField)
              .map((p) => p.toMap())
              .toList()),
      'hasMapperConstructorParameters': mapperConstructorParameters.isNotEmpty,
      'hasMapperConstructorParameterAssignments': mapperConstructorParameters
          .where((p) => p.needsAssignment && p.isField)
          .isNotEmpty,
      'mapperConstructorBodyAssignments': toMustacheList(
          mapperConstructorParameters
              .where((p) => p.isLate)
              .map((p) => p.toMap())
              .toList()),
      'hasMapperConstructorBody':
          mapperConstructorParameters.where((p) => p.isLate).isNotEmpty,
      'needsReader': needsReader,
      'registerGlobally': registerGlobally,
    };
  }
}

class LiteralMapperTemplateData extends GeneratedMapperTemplateData {
  static final rdfLanguageDatatype = Code.combine([
    Code.type('Rdf', importUri: importRdfVocab),
    Code.value('.langString')
  ]).toMap();

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
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required this.datatype,
    required this.toLiteralTermMethod,
    required this.fromLiteralTermMethod,
    required this.rdfValue,
    required this.rdfLanguageTag,
    required List<ParameterData> constructorParameters,
    required List<ParameterData> nonConstructorFields,
    required bool registerGlobally,
    required List<PropertyData> properties,
  })  : constructorParameters = constructorParameters,
        nonConstructorFields = nonConstructorFields,
        registerGlobally = registerGlobally,
        properties = properties,
        super(contextProviders: const []);

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

class IriMapperTemplateData extends GeneratedMapperTemplateData {
  /// IRI strategy information
  final IriData iriStrategy;

  /// List of parameters for this constructor
  final List<ParameterData> constructorParameters;

  /// List of non-constructor fields that are IRI parts
  final List<ParameterData> nonConstructorFields;

  /// Property mapping information
  final List<PropertyData> properties;

  final bool needsReader;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  final VariableNameData? singleMappedValue;

  const IriMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required IriData iriStrategy,
    required super.contextProviders,
    required List<ParameterData> constructorParameters,
    required List<ParameterData> nonConstructorFields,
    required bool needsReader,
    required bool registerGlobally,
    required List<PropertyData> properties,
    this.singleMappedValue,
  })  : iriStrategy = iriStrategy,
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
      'singleMappedValue': singleMappedValue?.toMap(),
      'hasSingleMappedValue': singleMappedValue != null,
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

  final bool isField;

  const ContextProviderData({
    required this.variableName,
    required this.privateFieldName,
    required this.parameterName,
    required this.placeholder,
    this.isField = true,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'privateFieldName': privateFieldName,
        'parameterName': parameterName,
        'placeholder': placeholder,
        'isField': isField,
      };
}

class VariableNameData {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  const VariableNameData({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'placeholder': placeholder,
        'isString': isString,
        'isMappedValue': isMappedValue,
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

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  const IriTemplateData({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
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
      'interpolatedTemplate': interpolatedTemplate,
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
  final bool hasFullIriPartTemplate;
  final MapperRefData? mapper;
  final bool hasMapper;
  final List<IriPartData> iriMapperParts;

  const IriData({
    this.template,
    required this.hasFullIriPartTemplate,
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
        'requiresIriParsing': !hasFullIriPartTemplate &&
            iriMapperParts
                .any((p) => !p.isRdfProperty && p.dartPropertyName.isNotEmpty),
        'hasFullIriPartTemplate': hasFullIriPartTemplate
      };
}

class ConstructorParameterData {
  final Code type;
  final String parameterName;
  final String fieldName;
  final ResolvableInstantiationCodeData? defaultValue;
  final bool isLate;
  final bool isField;

  bool get needsAssignment => parameterName != fieldName && !isLate;

  ConstructorParameterData(
      {required this.type,
      required this.parameterName,
      required this.fieldName,
      required this.defaultValue,
      required this.isLate,
      this.isField = true});

  Map<String, dynamic> toMap() => {
        'type': type.toMap(),
        'parameterName': parameterName,
        'fieldName': fieldName,
        'needsAssignment': needsAssignment,
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': defaultValue != null,
        'isLate': isLate,
        'isField': isField,
      };
}

/// Data for constructor parameters
class ParameterData {
  final String name;
  final Code dartType;
  final bool isRequired;
  final bool isFieldNullable;
  final bool isIriPart;
  final bool isRdfProperty;
  final bool isNamed;
  final String? iriPartName;
  final Code? predicate;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
  final Code? mapperSerializerCode;
  final Code? mapperDeserializerCode;
  final String? mapperFieldName;
  final String? mapperParameterSerializer;
  final String? mapperParameterDeserializer;
  final Code readerMethod;

  final bool isMap;
  final bool isList;
  final bool isSet;
  final bool isCollection;

  const ParameterData({
    required this.name,
    required this.dartType,
    required this.isRequired,
    required this.isFieldNullable,
    required this.isIriPart,
    required this.isRdfProperty,
    required this.isNamed,
    required this.iriPartName,
    required this.predicate,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.mapperFieldName,
    required this.mapperParameterSerializer,
    required this.mapperParameterDeserializer,
    required this.mapperSerializerCode,
    required this.mapperDeserializerCode,
    required this.readerMethod,
    required this.isMap,
    required this.isList,
    required this.isSet,
    required this.isCollection,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartType': dartType.toMap(),
        // if default value is provided, then it is not required
        'isRequired': isRequired && !hasDefaultValue,
        'isFieldNullable': isFieldNullable,
        'useOptionalReader': isFieldNullable || hasDefaultValue,
        'isIriPart': isIriPart && !isRdfProperty,
        'isRdfProperty': isRdfProperty,
        'isNamed': isNamed,
        'iriPartName': iriPartName,
        'predicate': predicate?.toMap(),
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': hasDefaultValue,
        'isRdfValue': isRdfValue,
        'isRdfLanguageTag': isRdfLanguageTag,
        'hasMapper': mapperFieldName != null,
        'mapperFieldName': mapperFieldName,
        'mapperParameterSerializer': mapperParameterSerializer,
        'mapperSerializerCode': mapperSerializerCode?.toMap(),
        'mapperDeserializerCode': mapperDeserializerCode?.toMap(),
        'mapperParameterDeserializer': mapperParameterDeserializer,
        'readerMethod': readerMethod.toMap(),
        'isMap': isMap,
        'isList': isList,
        'isSet': isSet,
        'isCollection': isCollection,
      };
}

/// Data for RDF properties
class PropertyData {
  final String propertyName;
  final bool isRequired;
  final bool isFieldNullable;
  final bool isRdfProperty;
  final bool include;
  final Code? predicate;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool includeDefaultsInSerialization;
  final String? mapperFieldName;
  final String? mapperParameterSerializer;
  final String? mapperParameterDeserializer;
  final Code? mapperSerializerCode;
  final Code? mapperDeserializerCode;
  final bool isCollection;
  final bool isMap;
  final Code readerMethod;
  final Code serializerMethod;
  final Code? dartType;
  final bool isList;
  final bool isSet;

  const PropertyData({
    required this.propertyName,
    required this.isRequired,
    required this.isFieldNullable,
    required this.isRdfProperty,
    required this.include,
    this.predicate,
    this.defaultValue,
    required this.hasDefaultValue,
    required this.includeDefaultsInSerialization,
    required this.mapperFieldName,
    required this.mapperParameterSerializer,
    required this.mapperParameterDeserializer,
    required this.mapperSerializerCode,
    required this.mapperDeserializerCode,
    required this.isCollection,
    required this.isMap,
    required this.readerMethod,
    required this.serializerMethod,
    this.dartType,
    required this.isList,
    required this.isSet,
  });

  Map<String, dynamic> toMap() => {
        'propertyName': propertyName,
        'isRequired': isRequired,
        'isFieldNullable': isFieldNullable,
        'useOptionalSerialization': isFieldNullable,
        'isRdfProperty': isRdfProperty,
        'include': include,
        'predicate': predicate?.toMap(),
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': hasDefaultValue,
        'includeDefaultsInSerialization': includeDefaultsInSerialization,
        'useConditionalSerialization':
            hasDefaultValue && !includeDefaultsInSerialization,
        'mapperFieldName': mapperFieldName,
        'mapperParameterSerializer': mapperParameterSerializer,
        'mapperParameterDeserializer': mapperParameterDeserializer,
        'hasMapper': mapperFieldName != null,
        'mapperSerializerCode': mapperSerializerCode?.toMap(),
        'mapperDeserializerCode': mapperDeserializerCode?.toMap(),
        'isCollection': isCollection,
        'isMap': isMap,
        'readerMethod': readerMethod.toMap(),
        'serializerMethod': serializerMethod.toMap(),
        'dartType': dartType?.toMap(),
        'isList': isList,
        'isSet': isSet,
      };
}

/// Template data for generating enum literal mappers.
///
/// This class contains all data needed to render mustache templates
/// for enum mappers annotated with @RdfLiteral.
class EnumLiteralMapperTemplateData extends GeneratedMapperTemplateData {
  /// The datatype for literal serialization
  final Code? datatype;

  /// List of enum values with their serialization mappings
  final List<Map<String, dynamic>> enumValues;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  const EnumLiteralMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    this.datatype,
    required this.enumValues,
    required this.registerGlobally,
  }) : super(contextProviders: const []);

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'datatype': datatype?.toMap(),
      'hasDatatype': datatype != null,
      'enumValues': toMustacheList(enumValues),
      'registerGlobally': registerGlobally,
    };
  }
}

/// Template data for generating enum IRI mappers.
///
/// This class contains all data needed to render mustache templates
/// for enum mappers annotated with @RdfIri.
class EnumIriMapperTemplateData extends GeneratedMapperTemplateData {
  /// IRI template for serialization
  final String? template;

  /// Regex pattern for deserialization
  final String? regexPattern;

  /// Interpolated template for serialization
  final String? interpolatedTemplate;

  /// List of enum values with their serialization mappings
  final List<Map<String, dynamic>> enumValues;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  /// Whether this uses a full IRI part template (no regex parsing needed)
  final bool hasFullIriPartTemplate;

  const EnumIriMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    this.template,
    this.regexPattern,
    this.interpolatedTemplate,
    required this.enumValues,
    required super.contextProviders,
    required this.registerGlobally,
    required this.hasFullIriPartTemplate,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'template': template,
      'hasTemplate': template != null,
      'regexPattern': regexPattern,
      'interpolatedTemplate': interpolatedTemplate,
      'enumValues': toMustacheList(enumValues),
      'contextProviders':
          toMustacheList(contextProviders.map((p) => p.toMap()).toList()),
      'hasContextProviders': contextProviders.isNotEmpty,
      'registerGlobally': registerGlobally,
      'hasFullIriPartTemplate': hasFullIriPartTemplate,
      'requiresIriParsing': !hasFullIriPartTemplate,
    };
  }
}
