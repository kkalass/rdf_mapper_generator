library;

import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

import '../templates/code.dart';

class ResolvedMapperFileModel {
  /// The import URI for the generated mapper file
  final String packageName;

  /// The source path of the original Dart file
  final String originalSourcePath;
  final String mapperFileImportUri;

  /// The list of mappers defined in this file
  final List<ResolvedMapperModel> mappers;
  final Map<String, String> importAliasByImportUri;

  const ResolvedMapperFileModel({
    required this.packageName,
    required this.originalSourcePath,
    required this.importAliasByImportUri,
    required this.mapperFileImportUri,
    required this.mappers,
  });

  @override
  String toString() {
    return 'ResolvedMapperFileModel{importUri: $mapperFileImportUri, mappers: $mappers}';
  }
}

/// Represents a mapper that will be generated, with its dependencies clearly defined
sealed class ResolvedMapperModel {
  /// Unique identifier for this mapper
  MapperId get id;

  /// The class this mapper handles
  Code get mappedClass;

  /// the type of mapper
  MapperType get type;

  /// Whether this mapper should be registered globally
  bool get registerGlobally;

  Code get interfaceClass => Code.combine([
        Code.literal(type.dartInterfaceName),
        Code.literal('<'),
        mappedClass,
        Code.literal('>')
      ]);

  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
  );
}

sealed class GeneratedResolvedMapperModel extends ResolvedMapperModel {
  /// The generated mapper class name
  Code get implementationClass;
  List<ConstructorParameterResolvedModelNew> get mapperConstructorParametersNew;

  List<FieldResolvedModel> get mapperFields;
}

class ConstructorParameterResolvedModelNew {
  final Code type;
  final String paramName;
  final String? associatedFieldName;
  final DependencyModel? dependency;

  ConstructorParameterResolvedModelNew(
      {required this.type,
      required this.paramName,
      required this.associatedFieldName,
      required this.dependency});
}

class ConstructorParameterResolvedModel {
  final Code type;
  final String parameterName;
  final String fieldName;
  final ResolvableInstantiationCodeData? defaultValue;
  bool isLate;
  bool isField;

  bool get needsAssignment => parameterName != fieldName && !isLate;

  ConstructorParameterResolvedModel(
      {required this.type,
      required this.parameterName,
      required this.fieldName,
      required this.defaultValue,
      required this.isLate,
      this.isField = true});

  ConstructorParameterData toTemplateData(ValidationContext context) {
    return ConstructorParameterData(
      type: type,
      parameterName: parameterName,
      fieldName: fieldName,
      defaultValue: defaultValue,
      isLate: isLate,
      isField: isField,
    );
  }
}

/// A mapper for global resources
class ResourceResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperId id;

  @override
  MapperType get type => iriStrategy == null
      ? MapperType.localResource
      : MapperType.globalResource;

  @override
  final Code mappedClass;

  final MappedClassResolvedModel mappedClassModel;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  final Code? typeIri;

  final Code termClass;

  /// IRI strategy information
  final IriResolvedModel? iriStrategy;

  /// Context variable providers needed for IRI generation
  @override
  // FIXME: implement mapperFields
  List<FieldResolvedModel> get mapperFields => const [];
  // FIXME: implement mapperConstructorParametersNew
  List<ConstructorParameterResolvedModelNew>
      get mapperConstructorParametersNew => const [];
  final List<ConstructorParameterResolvedModel> mapperConstructorParameters;
  final List<ContextProviderResolvedModel> contextProviders;
  final bool needsReader;

  ResourceResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.mappedClassModel,
    required this.implementationClass,
    required this.registerGlobally,
    required this.typeIri,
    required this.termClass,
    required this.iriStrategy,
    required this.mapperConstructorParameters,
    required this.contextProviders,
    required this.needsReader,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
  ) {
    return ResourceMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        registerGlobally: registerGlobally,
        typeIri: typeIri,
        termClass: termClass,
        iriStrategy: iriStrategy?.toTemplateData(context),
        contextProviders:
            contextProviders.map((p) => p.toTemplateData(context)).toList(),
        constructorParameters: mappedClassModel.constructorParameters
            .map((p) => p.toTemplateData(context))
            .toList(growable: false),
        needsReader: needsReader,
        properties: mappedClassModel.properties
            .map((p) => p.toTemplateData(context))
            .toList(growable: false),
        nonConstructorFields: mappedClassModel.nonConstructorRdfFields
            .map((p) => p.toTemplateData(context))
            .toList(growable: false),
        mapperConstructorParameters: mapperConstructorParameters
            .map((e) => e.toTemplateData(context))
            .toList(growable: false));
  }
}

class ParameterResolvedModel {
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

  const ParameterResolvedModel({
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

  ParameterData toTemplateData(ValidationContext context) {
    return ParameterData(
      name: name,
      dartType: dartType,
      isRequired: isRequired,
      isFieldNullable: isFieldNullable,
      isIriPart: isIriPart,
      isRdfProperty: isRdfProperty,
      isNamed: isNamed,
      iriPartName: iriPartName,
      predicate: predicate,
      defaultValue: defaultValue,
      hasDefaultValue: hasDefaultValue,
      isRdfValue: isRdfValue,
      isRdfLanguageTag: isRdfLanguageTag,
      mapperFieldName: mapperFieldName,
      mapperParameterSerializer: mapperParameterSerializer,
      mapperParameterDeserializer: mapperParameterDeserializer,
      mapperSerializerCode: mapperSerializerCode,
      mapperDeserializerCode: mapperDeserializerCode,
      readerMethod: readerMethod,
      isMap: isMap,
      isList: isList,
      isSet: isSet,
      isCollection: isCollection,
    );
  }
}

class PropertyResolvedModel {
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

  const PropertyResolvedModel({
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

  PropertyData toTemplateData(ValidationContext context) {
    return PropertyData(
      propertyName: propertyName,
      isRequired: isRequired,
      isFieldNullable: isFieldNullable,
      isRdfProperty: isRdfProperty,
      include: include,
      predicate: predicate,
      defaultValue: defaultValue,
      hasDefaultValue: hasDefaultValue,
      includeDefaultsInSerialization: includeDefaultsInSerialization,
      mapperFieldName: mapperFieldName,
      mapperParameterSerializer: mapperParameterSerializer,
      mapperParameterDeserializer: mapperParameterDeserializer,
      mapperSerializerCode: mapperSerializerCode,
      mapperDeserializerCode: mapperDeserializerCode,
      isCollection: isCollection,
      isMap: isMap,
      readerMethod: readerMethod,
      serializerMethod: serializerMethod,
      dartType: dartType ?? Code.literal('dynamic'),
      isList: isList,
      isSet: isSet,
    );
  }
}

class MappedClassResolvedModel {
  final Code className;
  final List<ParameterResolvedModel> constructorParameters;
  final List<ParameterResolvedModel> constructorRdfFields;
  final List<ParameterResolvedModel> nonConstructorRdfFields;
  final List<PropertyResolvedModel> properties;

  List<ParameterResolvedModel> get allRdfFields =>
      [...constructorRdfFields, ...nonConstructorRdfFields];

  const MappedClassResolvedModel(
      {required this.className,
      required this.constructorParameters,
      required this.constructorRdfFields,
      required this.nonConstructorRdfFields,
      required this.properties});

  @override
  String toString() => 'MappedClass(className: $className)';
}

class ContextProviderResolvedModel {
  /// The name of the context variable
  final String variableName;

  /// The name of the private field that stores the provider
  final String privateFieldName;

  /// The name of the constructor parameter
  final String parameterName;

  /// The placeholder pattern to replace in IRI templates (e.g., '{baseUri}')
  final String placeholder;

  final bool isField;
  final Code type;
  const ContextProviderResolvedModel(
      {required this.variableName,
      required this.privateFieldName,
      required this.parameterName,
      required this.placeholder,
      this.isField = true,
      this.type = const Code.literal('String Function()')});

  ContextProviderData toTemplateData(ValidationContext context) {
    return ContextProviderData(
      variableName: variableName,
      privateFieldName: privateFieldName,
      parameterName: parameterName,
      placeholder: placeholder,
      isField: isField,
      type: type,
    );
  }
}

/// A mapper for IRI terms
sealed class IriResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperId id;

  @override
  final MapperType type = MapperType.iri;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameResolvedModel> propertyVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  final VariableNameResolvedModel? singleMappedValue;

  /// FIXME: wrong abstraction
  final List<ContextProviderResolvedModel> contextProviders;

  final List<ConstructorParameterResolvedModelNew>
      mapperConstructorParametersNew;

  @override
  final List<FieldResolvedModel> mapperFields;

  IriResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.propertyVariables,
    required this.interpolatedTemplate,
    required this.regexPattern,
    required this.singleMappedValue,
    required this.contextProviders,
    required this.mapperConstructorParametersNew,
    required this.mapperFields,
  });
}

class IriClassResolvedMapperModel extends IriResolvedMapperModel {
  final MappedClassResolvedModel mappedClassModel;
  IriClassResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required this.mappedClassModel,
    required super.implementationClass,
    required super.registerGlobally,
    required super.propertyVariables,
    required super.interpolatedTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.contextProviders,
    required super.mapperConstructorParametersNew,
    required super.mapperFields,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
  ) {
    return IriMapperTemplateData(
      className: mappedClass,
      mapperClassName: implementationClass,
      mapperInterfaceName: interfaceClass,
      propertyVariables:
          propertyVariables.map((v) => v.toTemplateData(context)).toSet(),
      interpolatedTemplate: interpolatedTemplate,
      regexPattern: regexPattern,
      contextProviders:
          contextProviders.map((p) => p.toTemplateData(context)).toList(),
      constructorParameters: mappedClassModel.constructorParameters
          .map((p) => p.toTemplateData(context))
          .toList(growable: false),
      nonConstructorFields: mappedClassModel.nonConstructorRdfFields
          .map((p) => p.toTemplateData(context))
          .toList(growable: false),
      registerGlobally: registerGlobally,
      singleMappedValue: singleMappedValue?.toTemplateData(context),
    );
  }
}

class IriEnumResolvedMapperModel extends IriResolvedMapperModel {
  final List<EnumValueModel> enumValues;
  final bool hasFullIriTemplate;
  IriEnumResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required this.enumValues,
    required this.hasFullIriTemplate,
    required super.implementationClass,
    required super.registerGlobally,
    required super.propertyVariables,
    required super.interpolatedTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.contextProviders,
    required super.mapperConstructorParametersNew,
    required super.mapperFields,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
  ) {
    return EnumIriMapperTemplateData(
      className: mappedClass,
      mapperClassName: implementationClass,
      mapperInterfaceName: interfaceClass,
      enumValues: enumValues.map((e) => e.toTemplateData(context)).toList(),
      interpolatedTemplate: interpolatedTemplate,
      regexPattern: regexPattern,
      contextProviders:
          contextProviders.map((p) => p.toTemplateData(context)).toList(),
      registerGlobally: registerGlobally,
      hasFullIriPartTemplate: hasFullIriTemplate,
      // TODO: we could use a singleMappedValue here
      //singleMappedValue: singleMappedValue
    );
  }
}

/// A mapper for literal terms
sealed class LiteralResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperType type = MapperType.literal;

  @override
  final MapperId id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  @override
  List<ConstructorParameterResolvedModelNew>
      get mapperConstructorParametersNew => const [];

  @override
  List<FieldResolvedModel> get mapperFields => const [];

  final Code? datatype;

  final String? fromLiteralTermMethod;

  final String? toLiteralTermMethod;

  LiteralResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.datatype,
    required this.fromLiteralTermMethod,
    required this.toLiteralTermMethod,
  });

  bool get isMethodBased =>
      fromLiteralTermMethod != null && toLiteralTermMethod != null;
}

class LiteralClassResolvedMapperModel extends LiteralResolvedMapperModel {
  final MappedClassResolvedModel mappedClassModel;

  ParameterResolvedModel? get rdfValueField =>
      mappedClassModel.allRdfFields.where((p) => p.isRdfValue).singleOrNull;

  ParameterResolvedModel? get rdfLanguageField => mappedClassModel.allRdfFields
      .where((p) => p.isRdfLanguageTag)
      .singleOrNull;

  LiteralClassResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.registerGlobally,
    required super.datatype,
    required this.mappedClassModel,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(ValidationContext context) =>
      LiteralMapperTemplateData(
          className: mappedClass,
          mapperClassName: implementationClass,
          mapperInterfaceName: interfaceClass,
          datatype: datatype,
          fromLiteralTermMethod: fromLiteralTermMethod,
          toLiteralTermMethod: toLiteralTermMethod,
          constructorParameters: mappedClassModel.constructorParameters
              .map((p) => p.toTemplateData(context))
              .toList(growable: false),
          nonConstructorFields: mappedClassModel.nonConstructorRdfFields
              .map((p) => p.toTemplateData(context))
              .toList(growable: false),
          registerGlobally: registerGlobally,
          properties: mappedClassModel.properties
              .map((p) => p.toTemplateData(context))
              .toList(),
          rdfValue: rdfValueField?.toTemplateData(context),
          rdfLanguageTag: rdfLanguageField?.toTemplateData(context));
}

class IriPartResolvedModel {
  final String name;
  final String dartPropertyName;
  final bool isRdfProperty;

  const IriPartResolvedModel({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  IriPartData toTemplateData(ValidationContext context) {
    return IriPartData(
      name: name,
      dartPropertyName: dartPropertyName,
      isRdfProperty: isRdfProperty,
    );
  }
}

class VariableNameResolvedModel {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  const VariableNameResolvedModel({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  VariableNameData toTemplateData(ValidationContext context) {
    return VariableNameData(
      variableName: variableName,
      placeholder: placeholder,
      isString: isString,
      isMappedValue: isMappedValue,
    );
  }
}

class IriTemplateResolvedModel {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameResolvedModel> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameResolvedModel> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<VariableNameResolvedModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  const IriTemplateResolvedModel({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
  });

  IriTemplateData toTemplateData(ValidationContext context) {
    return IriTemplateData(
      template: template,
      variables: variables.map((e) => e.toTemplateData(context)).toSet(),
      propertyVariables:
          propertyVariables.map((e) => e.toTemplateData(context)).toSet(),
      contextVariables:
          contextVariables.map((e) => e.toTemplateData(context)).toSet(),
      regexPattern: regexPattern,
      interpolatedTemplate: interpolatedTemplate,
    );
  }
}

class IriResolvedModel {
  final IriTemplateResolvedModel? template;
  final bool hasFullIriPartTemplate;
  final MapperRefResolvedModel? mapper;
  final bool hasMapper;
  final List<IriPartResolvedModel> iriMapperParts;

  const IriResolvedModel({
    this.template,
    required this.hasFullIriPartTemplate,
    this.mapper,
    this.hasMapper = false,
    required this.iriMapperParts,
  });

  bool get hasTemplate => template != null;

  IriData toTemplateData(ValidationContext context) => IriData(
      template: template?.toTemplateData(context),
      hasFullIriPartTemplate: hasFullIriPartTemplate,
      mapper: mapper?.toTemplateData(context),
      hasMapper: hasMapper,
      iriMapperParts:
          iriMapperParts.map((e) => e.toTemplateData(context)).toList());
}

class MapperRefResolvedModel {
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

  const MapperRefResolvedModel({
    this.name,
    required this.type,
    this.isNamed = false,
    this.isTypeBased = false,
    this.isInstance = false,
    this.instanceInitializationCode,
  });

  MapperRefData toTemplateData(ValidationContext context) => MapperRefData(
      name: name,
      type: type,
      isNamed: isNamed,
      isTypeBased: isTypeBased,
      isInstance: isInstance,
      instanceInitializationCode: instanceInitializationCode);
}

class LiteralEnumResolvedMapperModel extends LiteralResolvedMapperModel {
  final List<EnumValueModel> enumValues;

  LiteralEnumResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.registerGlobally,
    required super.datatype,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required this.enumValues,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(ValidationContext context) =>
      EnumLiteralMapperTemplateData(
          className: mappedClass,
          mapperClassName: implementationClass,
          mapperInterfaceName: interfaceClass,
          datatype: datatype,
          fromLiteralTermMethod: fromLiteralTermMethod,
          toLiteralTermMethod: toLiteralTermMethod,
          registerGlobally: registerGlobally,
          enumValues:
              enumValues.map((e) => e.toTemplateData(context)).toList());
}

/// A custom mapper (externally provided)
class CustomResolvedMapperModel extends ResolvedMapperModel {
  @override
  final MapperId id;

  @override
  final MapperType type;

  @override
  final Code mappedClass;

  @override
  final bool registerGlobally;

  final String? instanceName;
  final Code? customMapperInstanceCode;
  final Code? implementationClass;

  CustomResolvedMapperModel(
      {required this.id,
      required this.type,
      required this.mappedClass,
      required this.registerGlobally,
      required this.instanceName,
      required this.customMapperInstanceCode,
      required this.implementationClass});

  @override
  MappableClassMapperTemplateData toTemplateData(ValidationContext context) {
    return CustomMapperTemplateData(
        className: mappedClass,
        mapperInterfaceType: interfaceClass,
        customMapperName: instanceName,
        isTypeBased: implementationClass != null,
        customMapperInstance: customMapperInstanceCode,
        registerGlobally: registerGlobally);
  }
}

class FieldResolvedModel {
  final String name;
  final Code type;

  FieldResolvedModel({required this.name, required this.type});
}
