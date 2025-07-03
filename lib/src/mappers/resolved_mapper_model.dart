library;

import 'package:meta/meta.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart'
    show RdfCollectionType;
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
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
  MapperRef get id;

  /// The class this mapper handles
  Code get mappedClass;

  /// the type of mapper
  MapperType get type;

  /// Whether this mapper should be registered globally
  bool get registerGlobally;

  Iterable<DependencyResolvedModel> get dependencies;

  List<ConstructorParameterResolvedModel> get mapperConstructorParameters =>
      dependencies.isEmpty
          ? const []
          : dependencies
              .map((d) => d.constructorParam)
              .nonNulls
              .toList(growable: false);

  List<FieldResolvedModel> get mapperFields => dependencies.isEmpty
      ? const []
      : dependencies.map((d) => d.field).nonNulls.toList(growable: false);

  Code get interfaceClass => Code.combine([
        Code.literal(type.dartInterfaceName),
        Code.literal('<'),
        mappedClass,
        Code.literal('>')
      ]);

  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri);
}

sealed class GeneratedResolvedMapperModel extends ResolvedMapperModel {
  /// The generated mapper class name
  Code get implementationClass;
}

class ConstructorParameterResolvedModel {
  final Code type;
  final String paramName;
  final Code? defaultValue;

  ConstructorParameterResolvedModel(
      {required this.type,
      required this.paramName,
      required this.defaultValue});

  bool get isRequired => defaultValue == null;

  @override
  String toString() {
    return 'ConstructorParameterResolvedModel{type: $type, paramName: $paramName, defaultValue: $defaultValue}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConstructorParameterResolvedModel) return false;
    return type == other.type &&
        paramName == other.paramName &&
        defaultValue == other.defaultValue;
  }

  @override
  int get hashCode =>
      type.hashCode ^ paramName.hashCode ^ defaultValue.hashCode;

  ConstructorParameterData toTemplateData(ValidationContext context) {
    return ConstructorParameterData(
      type: type,
      parameterName: paramName,
      defaultValue: defaultValue,
    );
  }
}

/// A mapper for global resources
class ResourceResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperRef id;

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

  final bool needsReader;
  final Iterable<DependencyResolvedModel> dependencies;

  final Iterable<ProvidesResolvedModel> provides;

  ResourceResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.mappedClassModel,
    required this.implementationClass,
    required this.registerGlobally,
    required this.typeIri,
    required this.termClass,
    required this.iriStrategy,
    required this.needsReader,
    required this.dependencies,
    required this.provides,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    final providesByVariableNames = {
      for (final p in provides) p.providerName: p
    };
    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    return ResourceMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        registerGlobally: registerGlobally,
        typeIri: typeIri,
        termClass: termClass,
        iriStrategy: iriStrategy?.toTemplateData(context),
        propertiesToDeserializeAsConstructorParameters:
            mappedClassData.constructorParameters,
        needsReader: needsReader,
        propertiesToSerialize: mappedClassData.propertiesToSerialize,
        propertiesToDeserializeAsFields:
            mappedClassData.nonConstructorRdfFields,
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context));
  }
}

class IriMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  IriMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class LiteralMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  LiteralMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class GlobalResourceMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  GlobalResourceMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class LocalResourceMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;

  LocalResourceMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

/// Information about collection properties
class CollectionResolvedModel {
  final bool isCollection;
  final bool isMap;
  final bool isIterable;
  final Code? elementTypeCode;

  const CollectionResolvedModel({
    required this.isCollection,
    required this.isMap,
    required this.isIterable,
    required this.elementTypeCode,
  });
}

class PropertyResolvedModel {
  final String propertyName;
  final bool isRequired;
  final bool isFieldNullable;
  final bool isRdfProperty;
  final bool isIriPart;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
  final String? iriPartName;
  final String? constructorParameterName;
  final bool isNamedConstructorParameter;

  final bool include;
  final Code? predicate;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool includeDefaultsInSerialization;
  final bool isCollection;
  final bool isMap;
  final Code dartType;
  final bool isList;
  final bool isSet;

  final CollectionResolvedModel collectionInfo;
  final RdfCollectionType collectionType;
  final IriMappingResolvedModel? iriMapping;
  final LiteralMappingResolvedModel? literalMapping;
  final GlobalResourceMappingResolvedModel? globalResourceMapping;
  final LocalResourceMappingResolvedModel? localResourceMapping;

  const PropertyResolvedModel({
    required this.propertyName,
    required this.isRequired,
    required this.isFieldNullable,
    required this.isRdfProperty,
    required this.isIriPart,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.iriPartName,
    required this.constructorParameterName,
    required this.isNamedConstructorParameter,
    required this.include,
    required this.predicate,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.includeDefaultsInSerialization,
    required this.isCollection,
    required this.isMap,
    required this.dartType,
    required this.isList,
    required this.isSet,
    required this.collectionInfo,
    required this.collectionType,
    required this.iriMapping,
    required this.literalMapping,
    required this.globalResourceMapping,
    required this.localResourceMapping,
  });

  bool get isConstructorParameter => constructorParameterName != null;

  Code? _generateBuilderCall({
    required Map<String, ProvidesResolvedModel> providesByProviderNames,
  }) {
    if (!isRdfProperty || predicate == null) {
      return null;
    }
    if (!include) {
      return null;
    }
    final (
      mapperParameterSerializer,
      mapperSerializerCode,
    ) = extractCustomSerializer(
      constructorParameterName ?? propertyName,
      this,
      providesByProviderNames,
    );

    final hasMapper =
        mapperParameterSerializer != null && mapperSerializerCode != null;

    final serializerMethod = getSerializerMethod(this);

    final serializerCall = Code.combine([
      Code.literal('.'),
      serializerMethod,
      Code.literal('('),
      Code.combine([
        predicate!,
        Code.combine([
          Code.literal('resource.'),
          Code.literal(propertyName),
        ]),
        if (hasMapper)
          Code.combine([
            Code.literal(mapperParameterSerializer),
            Code.literal(': '),
            mapperSerializerCode,
          ])
      ], separator: ', '),
      Code.literal(')'),
    ]);
    final checkDefaultValue =
        hasDefaultValue && !includeDefaultsInSerialization;
    final checkNullValue = isFieldNullable;
    final useConditionalSerialization = checkDefaultValue || checkNullValue;

    if (!useConditionalSerialization) {
      return serializerCall;
    }
    return Code.combine([
      Code.literal('.when('),
      Code.combine([
        Code.combine([
          if (checkDefaultValue)
            Code.literal('resource.$propertyName != $defaultValue'),
          if (checkNullValue) Code.literal('resource.$propertyName != null'),
        ], separator: ' && '),
        Code.combine([
          Code.literal('(b) => b'),
          serializerCall,
        ])
      ], separator: ', '),
      Code.literal(')'),
    ]);
  }

  Code? _generateReaderCall({
    required Map<String, ProvidesResolvedModel> providesByProviderNames,
  }) {
    if (!isRdfProperty || predicate == null) {
      return null;
    }
    final (
      mapperParameterDeserializer,
      mapperDeserializerCode,
    ) = _extractCustomDeserializer(
      constructorParameterName != null
          ? constructorParameterName!
          : propertyName,
      this,
      providesByProviderNames,
    );
    final hasMapper =
        mapperParameterDeserializer != null && mapperDeserializerCode != null;

    final readerMethod =
        getReaderMethod(this, !isFieldNullable && !hasDefaultValue);

    return Code.combine([
      Code.literal('reader.'),
      readerMethod,
      Code.literal('('),
      predicate!,
      if (hasMapper)
        Code.combine([
          Code.literal(', '),
          Code.literal(mapperParameterDeserializer),
          Code.literal(': '),
          mapperDeserializerCode,
        ]),
      Code.literal(')'),
      if (isCollection)
        if (isList)
          Code.literal('.toList()')
        else if (isSet)
          Code.literal('.toSet()'),
      if (hasDefaultValue)
        Code.combine([
          Code.literal(' ?? '),
          defaultValue!,
        ])
    ]);
  }

  PropertyData toTemplateData(
      ValidationContext context,
      Code className,
      Map<String, ProvidesResolvedModel> providesByProviderNames,
      String mapperImportUri) {
    final builderCall = _generateBuilderCall(
      providesByProviderNames: providesByProviderNames,
    );

    final readerCall = _generateReaderCall(
      providesByProviderNames: providesByProviderNames,
    );
    return PropertyData(
        propertyName: propertyName,
        isFieldNullable: isFieldNullable,
        isRdfProperty: isRdfProperty,
        isIriPart: isIriPart,
        isRdfValue: isRdfValue,
        isRdfLanguageTag: isRdfLanguageTag,
        iriPartName: iriPartName,
        name: constructorParameterName,
        isNamed: isNamedConstructorParameter,
        defaultValue: defaultValue,
        hasDefaultValue: hasDefaultValue,
        dartType: dartType,
        readerCall: readerCall,
        builderCall: builderCall);
  }
}

typedef IsRdfFieldFilter = bool Function(PropertyData property);

class MappedClassResolvedModel {
  final Code className;
  final List<PropertyResolvedModel> properties;
  final IsRdfFieldFilter _isRdfField;

  const MappedClassResolvedModel(
      {required this.className,
      required this.properties,
      required IsRdfFieldFilter isRdfFieldFilter})
      : _isRdfField = isRdfFieldFilter;

  @override
  String toString() => 'MappedClass(className: $className)';

  MappedClassData toTemplateData(
      ValidationContext context,
      Map<String, ProvidesResolvedModel> providesByProviderNames,
      String mapperImportUri) {
    final convertedProperties = properties
        .map((p) => p.toTemplateData(
            context, className, providesByProviderNames, mapperImportUri))
        .toList(growable: false);
    return MappedClassData(
      className: className,
      constructorParameters: convertedProperties
          .where((p) => p.isConstructorParameter)
          .toList(growable: false),
      constructorRdfFields: convertedProperties
          .where((p) => p.isConstructorParameter && _isRdfField(p))
          .toList(growable: false),
      nonConstructorRdfFields: convertedProperties
          .where((p) => !p.isConstructorParameter && _isRdfField(p))
          .toList(growable: false),
      properties: convertedProperties,
    );
  }
}

class MappedClassData {
  final Code className;
  final List<PropertyData> constructorParameters;
  final List<PropertyData> constructorRdfFields;
  final List<PropertyData> nonConstructorRdfFields;
  List<PropertyData> get propertiesToSerialize => properties;
  final List<PropertyData> properties;

  List<PropertyData> get allRdfFields =>
      [...constructorRdfFields, ...nonConstructorRdfFields];

  const MappedClassData(
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
  final MapperRef id;

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
  final Set<DependencyUsingVariableResolvedModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  final VariableNameResolvedModel? singleMappedValue;

  final Iterable<DependencyResolvedModel> dependencies;

  IriResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.propertyVariables,
    required this.contextVariables,
    required this.interpolatedTemplate,
    required this.regexPattern,
    required this.singleMappedValue,
    required this.dependencies,
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
    required super.contextVariables,
    required super.interpolatedTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.dependencies,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
    String mapperImportUri,
  ) {
    // This type of mapper does not provide any fields to children
    final providesByVariableNames = const <String, ProvidesResolvedModel>{};
    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    return IriMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        propertyVariables:
            propertyVariables.map((v) => v.toTemplateData(context)).toSet(),
        contextVariables:
            contextVariables.map((v) => v.toTemplateData(context)).toSet(),
        interpolatedTemplate: interpolatedTemplate,
        regexPattern: regexPattern,
        constructorParameters: mappedClassData.constructorParameters,
        nonConstructorFields: mappedClassData.nonConstructorRdfFields,
        registerGlobally: registerGlobally,
        singleMappedValue: singleMappedValue?.toTemplateData(context),
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context));
  }
}

MapperConstructorTemplateData _toMapperConstructorTemplateData(
  Code implementationClass,
  Iterable<DependencyResolvedModel> dependencies,
  ValidationContext context,
) {
  List<ConstructorParameterData> mapperConstructorParameters = dependencies
      .map((e) {
        final c = e.constructorParam?.toTemplateData(context);
        if (c?.defaultValue != null && (e.field?.isLate ?? false)) {
          return null; // skip late fields with default values
        } else {
          return c;
        }
      })
      .nonNulls
      .toSet() // deduplicate
      .toList(growable: false)
    ..sort(
      (a, b) => a.parameterName.compareTo(b.parameterName),
    );
  var hasAnyLateConstructorFields = dependencies
      .any((d) => d.constructorParam != null && (d.field?.isLate ?? false));
  bool isConst = !hasAnyLateConstructorFields;
  List<BodyAssignmentData> bodyAssignments = dependencies
      .where((p) =>
          p.constructorParam?.defaultValue != null &&
          (p.field?.isLate ?? false))
      .map((p) => BodyAssignmentData(
            fieldName: p.field!.name,
            defaultValue: p.constructorParam!.defaultValue!,
          ))
      .nonNulls
      .toSet() // deduplicate
      .toList()
    ..sort(
      (a, b) => a.fieldName.compareTo(b.fieldName),
    );
  List<ParameterAssignmentData> parameterAssignments = dependencies
      .where((p) => (p.field != null) && !(p.field?.isLate ?? false))
      .map((p) => ParameterAssignmentData(
            fieldName: p.field!.name,
            parameterName: p.constructorParam!.paramName,
          ))
      .toSet() // deduplicate
      .toList()
    ..sort((a, b) => a.parameterName.compareTo(b.parameterName));

  return MapperConstructorTemplateData(
    mapperClassName: implementationClass,
    parameterAssignments: parameterAssignments,
    bodyAssignments: bodyAssignments,
    mapperConstructorParameters: mapperConstructorParameters,
    isConst: isConst,
  );
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
    required super.contextVariables,
    required super.interpolatedTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.dependencies,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
    String mapperImportUri,
  ) {
    return EnumIriMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        enumValues: enumValues.map((e) => e.toTemplateData(context)).toList(),
        interpolatedTemplate: interpolatedTemplate,
        regexPattern: regexPattern,
        registerGlobally: registerGlobally,
        contextVariables:
            contextVariables.map((v) => v.toTemplateData(context)).toSet(),
        requiresIriParsing: !hasFullIriTemplate,
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context)
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
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  final Code? datatype;

  final String? fromLiteralTermMethod;

  final String? toLiteralTermMethod;

  final Iterable<DependencyResolvedModel> dependencies;

  LiteralResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.datatype,
    required this.fromLiteralTermMethod,
    required this.toLiteralTermMethod,
    required this.dependencies,
  });

  bool get isMethodBased =>
      fromLiteralTermMethod != null && toLiteralTermMethod != null;
}

class LiteralClassResolvedMapperModel extends LiteralResolvedMapperModel {
  final MappedClassResolvedModel mappedClassModel;

  LiteralClassResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.registerGlobally,
    required super.datatype,
    required this.mappedClassModel,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required super.dependencies,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    // This type of mapper does not provide any fields to children
    final providesByVariableNames = const <String, ProvidesResolvedModel>{};

    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    final rdfValueField =
        mappedClassData.allRdfFields.where((p) => p.isRdfValue).singleOrNull;

    final rdfLanguageField = mappedClassData.allRdfFields
        .where((p) => p.isRdfLanguageTag)
        .singleOrNull;

    return LiteralMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        datatype: datatype,
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod,
        constructorParameters: mappedClassData.constructorParameters,
        nonConstructorFields: mappedClassData.nonConstructorRdfFields,
        registerGlobally: registerGlobally,
        properties: mappedClassData.properties,
        rdfValue: rdfValueField,
        rdfLanguageTag: rdfLanguageField,
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context));
  }
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

  // FIXME: this corresponds to the provider - we need to reference it correctly

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

  @override
  String toString() {
    return 'VariableNameResolvedModel{variableName: $variableName, placeholder: $placeholder, isString: $isString, isMappedValue: $isMappedValue}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is VariableNameResolvedModel &&
        other.variableName == variableName &&
        other.placeholder == placeholder &&
        other.isString == isString &&
        other.isMappedValue == isMappedValue;
  }

  @override
  int get hashCode {
    return variableName.hashCode ^
        placeholder.hashCode ^
        isString.hashCode ^
        isMappedValue.hashCode;
  }
}

class DependencyUsingVariableResolvedModel {
  final String variableName;
  final Code code;

  const DependencyUsingVariableResolvedModel({
    required this.variableName,
    required this.code,
  });

  DependencyUsingVariableData toTemplateData(ValidationContext context) {
    return DependencyUsingVariableData(
      variableName: variableName,
      code: code,
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
  final Set<DependencyUsingVariableResolvedModel> contextVariables;

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
  final bool hasMapper;
  final List<IriPartResolvedModel> iriMapperParts;

  const IriResolvedModel({
    required this.template,
    required this.hasFullIriPartTemplate,
    required this.hasMapper,
    required this.iriMapperParts,
  });

  bool get hasTemplate => template != null;

  IriData toTemplateData(ValidationContext context) => IriData(
      template: template?.toTemplateData(context),
      hasFullIriPartTemplate: hasFullIriPartTemplate,
      hasMapper: hasMapper,
      iriMapperParts:
          iriMapperParts.map((e) => e.toTemplateData(context)).toList());
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
    required super.dependencies,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
          ValidationContext context, String mapperImportUri) =>
      EnumLiteralMapperTemplateData(
          className: mappedClass,
          mapperClassName: implementationClass,
          mapperInterfaceName: interfaceClass,
          datatype: datatype,
          fromLiteralTermMethod: fromLiteralTermMethod,
          toLiteralTermMethod: toLiteralTermMethod,
          registerGlobally: registerGlobally,
          enumValues: enumValues.map((e) => e.toTemplateData(context)).toList(),
          mapperFields: mapperFields
              .map((f) => f.toTemplateData(context))
              .toList(growable: false),
          mapperConstructor: _toMapperConstructorTemplateData(
              implementationClass, dependencies, context));
}

/// A custom mapper (externally provided)
class CustomResolvedMapperModel extends ResolvedMapperModel {
  @override
  final MapperRef id;

  @override
  final MapperType type;

  @override
  final Code mappedClass;

  @override
  final bool registerGlobally;

  final String? instanceName;
  final Code? customMapperInstanceCode;
  final Code? implementationClass;

  List<DependencyResolvedModel> get dependencies => const [];

  CustomResolvedMapperModel(
      {required this.id,
      required this.type,
      required this.mappedClass,
      required this.registerGlobally,
      required this.instanceName,
      required this.customMapperInstanceCode,
      required this.implementationClass});

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    return CustomMapperTemplateData(
        className: mappedClass,
        mapperInterfaceType: interfaceClass,
        customMapperName: instanceName,
        isTypeBased: implementationClass != null,
        customMapperInstance: customMapperInstanceCode,
        registerGlobally: registerGlobally);
  }
}

class DependencyResolvedModel {
  final DependencyId id;
  final FieldResolvedModel? field;
  final ConstructorParameterResolvedModel? constructorParam;
  final Code? usageCode;

  DependencyResolvedModel(
      {required this.id,
      required this.field,
      required this.constructorParam,
      required this.usageCode});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DependencyResolvedModel) return false;
    return id == other.id &&
        field == other.field &&
        constructorParam == other.constructorParam &&
        usageCode == other.usageCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        (field?.hashCode ?? 0) ^
        (constructorParam?.hashCode ?? 0) ^
        usageCode.hashCode;
  }

  @override
  String toString() {
    return 'DependencyResolvedModel{id: $id, field: $field, constructorParam: $constructorParam, usageCode: $usageCode}';
  }
}

class FieldResolvedModel {
  final String name;
  final Code type;
  final bool isLate;
  final bool isFinal;

  FieldResolvedModel(
      {required this.name,
      required this.type,
      required this.isLate,
      required this.isFinal});

  @override
  String toString() {
    return 'FieldResolvedModel{name: $name, type: $type, isLate: $isLate, isFinal: $isFinal}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FieldResolvedModel) return false;
    return name == other.name &&
        type == other.type &&
        isLate == other.isLate &&
        isFinal == other.isFinal;
  }

  @override
  int get hashCode {
    return name.hashCode ^ type.hashCode ^ isLate.hashCode ^ isFinal.hashCode;
  }

  FieldData toTemplateData(ValidationContext context) {
    return FieldData(
      name: name,
      type: type,
      isLate: isLate,
      isFinal: isFinal,
    );
  }
}

final class ProvidesResolvedModel {
  final String name;
  final String dartPropertyName;

  const ProvidesResolvedModel(
      {required this.name, required this.dartPropertyName});

  @override
  int get hashCode => Object.hash(name, dartPropertyName);

  String get providerName => '${name}Provider';

  @override
  bool operator ==(Object other) {
    if (other is! ProvidesModel) {
      return false;
    }
    return name == other.name && dartPropertyName == other.dartPropertyName;
  }

  @override
  String toString() {
    return 'ProvidesResolvedModel{name: $name, dartPropertyName: $dartPropertyName}';
  }
}

String _buildMapperFieldName(String fieldName) => '_' + fieldName + 'Mapper';

(
  String? parameterName,
  Code? code,
) _extractCustomDeserializer(
    String fieldName,
    PropertyResolvedModel? propertyInfo,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  final (paramName, resolvedMapper) = switch (propertyInfo) {
    PropertyResolvedModel(
      iriMapping: var iriMapping?,
    ) =>
      ('iriTermDeserializer', iriMapping.resolvedMapper),
    PropertyResolvedModel(
      literalMapping: var literalMapping?,
    ) =>
      ('literalTermDeserializer', literalMapping.resolvedMapper),
    PropertyResolvedModel(
      globalResourceMapping: var globalResourceMapping?,
    ) =>
      ('globalResourceDeserializer', globalResourceMapping.resolvedMapper),
    PropertyResolvedModel(
      localResourceMapping: var localResourceMapping?,
    ) =>
      ('localResourceDeserializer', localResourceMapping.resolvedMapper),
    _ => const (null, null)
  };
  if (paramName == null) {
    return const (null, null);
  }

  final mapperFieldName = _buildMapperFieldName(fieldName);
  final (parameterNames, generatedMapperName) =
      _extractGeneratedMapperInfos(resolvedMapper);

  return (
    paramName,
    generatedMapperName != null && parameterNames.isNotEmpty
        ? _buildMapperDeserializerCode(generatedMapperName, mapperFieldName,
            parameterNames, providesByConstructorParameterNames)
        : Code.literal(mapperFieldName),
  );
}

@visibleForTesting
(
  String? parameterName,
  Code? code,
) extractCustomSerializer(String fieldName, PropertyResolvedModel? propertyInfo,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  final (paramName, resolvedMapper) = switch (propertyInfo) {
    PropertyResolvedModel(
      iriMapping: var iriMapping?,
    ) =>
      ('iriTermSerializer', iriMapping.resolvedMapper),
    PropertyResolvedModel(
      literalMapping: var literalMapping?,
    ) =>
      ('literalTermSerializer', literalMapping.resolvedMapper),
    PropertyResolvedModel(
      globalResourceMapping: var globalResourceMapping?,
    ) =>
      ('resourceSerializer', globalResourceMapping.resolvedMapper),
    PropertyResolvedModel(
      localResourceMapping: var localResourceMapping?,
    ) =>
      ('resourceSerializer', localResourceMapping.resolvedMapper),
    _ => const (null, null)
  };

  if (paramName == null) {
    return const (null, null);
  }

  final mapperFieldName = _buildMapperFieldName(fieldName);
  final (parameterNames, generatedMapperName) =
      _extractGeneratedMapperInfos(resolvedMapper);

  return (
    paramName,
    generatedMapperName != null && parameterNames.isNotEmpty
        ? _buildMapperSerializerCode(generatedMapperName, mapperFieldName,
            parameterNames, providesByConstructorParameterNames)
        : Code.literal(mapperFieldName),
  );
}

(List<String>, Code?) _extractGeneratedMapperInfos(
    ResolvedMapperModel? resolvedMapper) {
  final generatedMapper =
      resolvedMapper is GeneratedResolvedMapperModel ? resolvedMapper : null;
  final parameterNames = (generatedMapper?.dependencies ?? const [])
      .where((e) => e.constructorParam != null)
      .map((e) => e.constructorParam!.paramName)
      .toSet()
      .toList(growable: false)
    ..sort();

  final generatedMapperName = generatedMapper?.implementationClass;
  return (parameterNames, generatedMapperName);
}

Code _buildMapperSerializerCode(
    Code mapperName,
    String mapperFieldName,
    List<String> mapperConstructorParameterNames,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  if (mapperConstructorParameterNames.isEmpty) {
    // No context variables at all, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  final hasProvides = mapperConstructorParameterNames
      .any((v) => providesByConstructorParameterNames.containsKey(v));
  if (!hasProvides) {
    // All context variables will be injected, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  return Code.combine([
    mapperName,
    Code.literal('('),
    ...mapperConstructorParameterNames.map((v) {
      final provides = providesByConstructorParameterNames[v];
      if (provides == null) {
        // context variable is not provided, so it will be injected as a field
        return Code.literal('${v}: _${v}, ');
      }
      return Code.literal(
          '${v}: () => resource.${provides.dartPropertyName}, ');
    }),
    Code.literal(')')
  ]);
}

@visibleForTesting
Code getReaderMethod(PropertyResolvedModel? propertyInfo, bool isRequired) {
  return switch (propertyInfo) {
    // Case 1: Property is a collection (not none), and it's specifically a Map.
    PropertyResolvedModel(
      collectionInfo: CollectionResolvedModel(isCollection: true, isMap: true),
      collectionType: final type
    )
        when type != RdfCollectionType.none =>
      const Code.literal('getMap'),

    // Case 2: Property is a collection (not none), and it's specifically an Iterable.
    PropertyResolvedModel(
      collectionInfo: CollectionResolvedModel(
        isCollection: true,
        isIterable: true,
        elementTypeCode: final elementType?
      ), // Destructure elementTypeCode here
      collectionType: final type
    )
        when type != RdfCollectionType.none =>
      codeGeneric1(Code.literal('getValues'), elementType),

    // Default Case: Any other scenario (not a collection, or collectionType is none, or just a single value)
    _ => isRequired ? const Code.literal('require') : Code.literal('optional'),
  };
}

@visibleForTesting
Code getSerializerMethod(PropertyResolvedModel? propertyInfo) =>
    switch (propertyInfo) {
      // Case 1: Property is a collection (not none), and it's specifically a Map.
      PropertyResolvedModel(
        collectionInfo: CollectionResolvedModel(
          isCollection: true,
          isMap: true
        ),
        collectionType: final type
      )
          when type != RdfCollectionType.none =>
        const Code.literal('addMap'),

      // Case 2: Property is a collection (not none), and it's specifically an Iterable.
      PropertyResolvedModel(
        collectionInfo: CollectionResolvedModel(
          isCollection: true,
          isIterable: true,
          elementTypeCode: final elementType?
        ), // Destructure elementTypeCode here
        collectionType: final type
      )
          when type != RdfCollectionType.none =>
        codeGeneric1(Code.literal('addValues'), elementType),

      // Default Case: Any other scenario (not a collection, or collectionType is none, or just a single value)
      _ => const Code.literal('addValue'),
    };

Code _buildMapperDeserializerCode(
    Code mapperClassName,
    String mapperFieldName,
    Iterable<String> constructorParameterNames,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  if (constructorParameterNames.isEmpty) {
    // No context variables at all, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  final hasProvides = constructorParameterNames
      .any((v) => providesByConstructorParameterNames.containsKey(v));
  if (!hasProvides) {
    // All context variables will be injected, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  // we will need to build our own initialization code
  return Code.combine([
    mapperClassName,
    Code.literal('('),
    ...constructorParameterNames.map((v) {
      final provides = providesByConstructorParameterNames[v];
      if (provides == null) {
        // context variable is not provided, so it will be injected as a field
        return Code.literal('${v}: _${v}, ');
      }
      return Code.literal(
          "${v}: () => throw Exception('Must not call provider for deserialization'), ");
    }),
    Code.literal(')')
  ]);
}
