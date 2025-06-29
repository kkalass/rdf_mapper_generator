/// Mapper Model Layer - Intermediate layer between Info and Template Data
///
/// This layer represents the business logic of mappers and their dependencies,
/// independent of code generation concerns.
///
/// FIXME: This is an intermediate state where we - in some parts - directly
/// create Data layer objects.

library;

import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:uuid/uuid.dart';

import '../templates/code.dart';

class MapperFileModel {
  /// The import URI for the generated mapper file
  final String packageName;

  /// The source path of the original Dart file
  final String originalSourcePath;
  final String mapperFileImportUri;

  /// The list of mappers defined in this file
  final List<MapperModel> mappers;
  final Map<String, String> importAliasByImportUri;

  const MapperFileModel({
    required this.packageName,
    required this.originalSourcePath,
    required this.importAliasByImportUri,
    required this.mapperFileImportUri,
    required this.mappers,
  });

  @override
  String toString() {
    return 'MapperFileModel{importUri: $mapperFileImportUri, mappers: $mappers}';
  }
}

class MapperId {
  final String id;

  const MapperId(this.id);

  static MapperId fromImplementationClass(Code mapperClassName) {
    return MapperId('Implementation:' + mapperClassName.code);
  }

  static MapperId fromInstanceName(String instance) {
    return MapperId('Instance:' + instance);
  }

  static MapperId fromInstantiationCode(Code instantiation) {
    return MapperId('Instantiation:' + instantiation.code);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapperId) return false;
    return id == other.id;
  }

  @override
  String toString() => 'MapperId($id)';
}

enum MapperType {
  globalResource('GlobalResourceMapper'),
  localResource('LocalResourceMapper'),
  iri('IriTermMapper'),
  literal('LiteralTermMapper'),
  ;

  final String dartInterfaceName;
  const MapperType(this.dartInterfaceName);
}

class ParameterModel {
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

  const ParameterModel({
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

  ParameterResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return ParameterResolvedModel(
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

class PropertyModel {
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

  const PropertyModel({
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

  PropertyResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return PropertyResolvedModel(
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

class MappedClassModel {
  final Code className;
  final List<ParameterModel> constructorParameters;
  final List<ParameterModel> constructorRdfFields;
  final List<ParameterModel> nonConstructorRdfFields;
  final List<PropertyModel> properties;

  List<ParameterModel> get allRdfFields =>
      [...constructorRdfFields, ...nonConstructorRdfFields];

  const MappedClassModel(
      {required this.className,
      required this.constructorParameters,
      required this.constructorRdfFields,
      required this.nonConstructorRdfFields,
      required this.properties});

  @override
  String toString() => 'MappedClass(className: $className)';

  MappedClassResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return MappedClassResolvedModel(
      className: className,
      constructorParameters: constructorParameters
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
      constructorRdfFields: constructorRdfFields
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
      nonConstructorRdfFields: nonConstructorRdfFields
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
      properties: properties
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
    );
  }
}

/// Contains information about an enum value and its serialized representation
class EnumValueModel {
  /// The name of the enum constant
  final String constantName;

  /// The serialized value (either custom from @RdfEnumValue or the constant name)
  final String serializedValue;

  const EnumValueModel({
    required this.constantName,
    required this.serializedValue,
  });

  Map<String, dynamic> toTemplateData(ValidationContext context) => {
        'constantName': constantName,
        'serializedValue': serializedValue,
      };
}

/// Represents a mapper that will be generated, with its dependencies clearly defined
sealed class MapperModel {
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

  /// Dependencies this mapper requires to function -
  /// note that this is not the same as constructor parameters,
  /// it can also represent instances that will be instantiated.
  ///
  /// It certainly is the basis for resolving the "external"
  /// dependencies though
  List<DependencyModel> get dependencies;

  /// Called once all mappers are known, in order to compute the correct
  /// constructor dependencies and other additional state.
  ///
  /// Note that the caller of this method has to take care to call this
  /// only on mappers which only reference dependencies that were already
  /// initialized.
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies);
}

sealed class GeneratedMapperModel extends MapperModel {
  /// The generated mapper class name
  Code get implementationClass;
}

class ContextProviderModel {
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
  const ContextProviderModel(
      {required this.variableName,
      required this.privateFieldName,
      required this.parameterName,
      required this.placeholder,
      this.isField = true,
      this.type = const Code.literal('String Function()')});

  ContextProviderResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return ContextProviderResolvedModel(
      variableName: variableName,
      privateFieldName: privateFieldName,
      parameterName: parameterName,
      placeholder: placeholder,
      isField: isField,
      type: type,
    );
  }
}

/// A mapper for global resources
class ResourceMapperModel extends GeneratedMapperModel {
  @override
  final MapperId id;

  @override
  MapperType get type => iriStrategy == null
      ? MapperType.localResource
      : MapperType.globalResource;

  @override
  final Code mappedClass;

  final MappedClassModel mappedClassModel;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  final Code? typeIri;

  final Code termClass;

  /// IRI strategy information
  final IriModel? iriStrategy;

  final List<ConstructorParameterModel> mapperConstructorParameters;
  final List<ContextProviderModel> contextProviders;
  final bool needsReader;

  ResourceMapperModel({
    required this.id,
    required this.mappedClass,
    required this.mappedClassModel,
    required this.implementationClass,
    required this.dependencies,
    required this.registerGlobally,
    required this.typeIri,
    required this.termClass,
    required this.iriStrategy,
    required this.mapperConstructorParameters,
    required this.contextProviders,
    required this.needsReader,
  });

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return ResourceResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      mappedClassModel: mappedClassModel.resolve(context, resolvedDependencies),
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      typeIri: typeIri,
      termClass: termClass,
      iriStrategy: iriStrategy?.resolve(
        context,
        resolvedDependencies,
      ),
      mapperConstructorParameters: mapperConstructorParameters
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
      contextProviders: contextProviders
          .map((p) => p.resolve(context, resolvedDependencies))
          .toList(growable: false),
      needsReader: needsReader,
    );
  }
}

class ConstructorParameterModelNew {
  final Code type;
  final String paramName;
  final String? associatedFieldName;
  final DependencyModel? dependency;

  ConstructorParameterModelNew(
      {required this.type,
      required this.paramName,
      required this.associatedFieldName,
      required this.dependency});

  ConstructorParameterResolvedModelNew resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return ConstructorParameterResolvedModelNew(
        type: type,
        paramName: paramName,
        associatedFieldName: associatedFieldName,
        dependency: dependency //?.resolve(context, resolvedDependencies),
        );
  }
}

class ConstructorParameterModel {
  final Code type;
  final String parameterName;
  final String fieldName;
  final ResolvableInstantiationCodeData? defaultValue;
  bool isLate;
  bool isField;

  bool get needsAssignment => parameterName != fieldName && !isLate;

  ConstructorParameterModel(
      {required this.type,
      required this.parameterName,
      required this.fieldName,
      required this.defaultValue,
      required this.isLate,
      this.isField = true});

  ConstructorParameterResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return ConstructorParameterResolvedModel(
        type: type,
        parameterName: parameterName,
        fieldName: fieldName,
        defaultValue: defaultValue,
        isLate: isLate,
        isField: isField);
  }
}

final class VariableForDependencyModel {
  final VariableName name;
  final DependencyId dependencyId;

  VariableForDependencyModel({required this.name, required this.dependencyId});
}

/// A mapper for IRI terms
sealed class IriMapperModel extends GeneratedMapperModel {
  @override
  final MapperId id;

  @override
  final MapperType type = MapperType.iri;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  /// FIXME partially wrong layer
  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameModel> propertyVariables;

  final Set<VariableForDependencyModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  final VariableNameModel? singleMappedValue;

  IriMapperModel(
      {required this.id,
      required this.mappedClass,
      required this.implementationClass,
      required this.registerGlobally,
      required this.dependencies,
      required this.propertyVariables,
      required this.interpolatedTemplate,
      required this.regexPattern,
      required this.singleMappedValue,
      required this.contextVariables});

  (
    List<ContextProviderResolvedModel>,
    List<FieldResolvedModel>,
    List<ConstructorParameterResolvedModelNew>
  ) resolveDepencencies(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    var dependenciesById = {for (var dep in dependencies) dep.id: dep};
    var resolvedVariables = contextVariables.map((v) {
      final dependency = dependenciesById[v.dependencyId];
      if (dependency is! GenericDependency) {
        throw StateError(
            'No dependency found for variable ${v.name} with id ${v.dependencyId}');
      }
      final paramName = dependency.name;
      final privateFieldName = '_${paramName}';
      final type = dependency.type;

      final field = FieldResolvedModel(
        name: privateFieldName,
        type: type,
      );
      final constructorParameter = ConstructorParameterResolvedModelNew(
        paramName: paramName,
        type: type,
        associatedFieldName: privateFieldName,
        dependency: dependency,
      );

      // FIXME: this should rather be something like "variable assignment data"
      final contextProvider = ContextProviderResolvedModel(
        variableName: v.name.dartPropertyName,
        parameterName: constructorParameter.paramName,
        privateFieldName: constructorParameter.associatedFieldName!,
        type: constructorParameter.type,
        isField: true,
        // FIXME What do we need the placeholder for here?
        placeholder: v.name.canBeUri ? '{+${v.name.name}}' : '{${v.name.name}}',
      );
      return (field, constructorParameter, contextProvider);
    });
    final contextProviders =
        resolvedVariables.map((v) => v.$3).toList(growable: false);
    final fields = resolvedVariables.map((v) => v.$1).toList(growable: false);
    final constructorParameters =
        resolvedVariables.map((v) => v.$2).toList(growable: false);
    return (contextProviders, fields, constructorParameters);
  }
}

class IriClassMapperModel extends IriMapperModel {
  final MappedClassModel mappedClassModel;

  IriClassMapperModel(
      {required super.id,
      required super.mappedClass,
      required this.mappedClassModel,
      required super.implementationClass,
      required super.registerGlobally,
      required super.dependencies,
      required super.propertyVariables,
      required super.interpolatedTemplate,
      required super.regexPattern,
      required super.singleMappedValue,
      required super.contextVariables});

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    final (contextProviders, fields, constructorParameters) =
        resolveDepencencies(context, resolvedDependencies);
    return IriClassResolvedMapperModel(
        id: id,
        mappedClass: mappedClass,
        mappedClassModel:
            mappedClassModel.resolve(context, resolvedDependencies),
        implementationClass: implementationClass,
        registerGlobally: registerGlobally,
        mapperFields: fields,
        propertyVariables: propertyVariables
            .map((v) => v.resolve(context, resolvedDependencies))
            .toSet(),
        interpolatedTemplate: interpolatedTemplate,
        regexPattern: regexPattern,
        singleMappedValue:
            singleMappedValue?.resolve(context, resolvedDependencies),
        mapperConstructorParametersNew: constructorParameters,
        contextProviders: contextProviders);
  }
}

class IriEnumMapperModel extends IriMapperModel {
  final List<EnumValueModel> enumValues;
  final bool hasFullIriTemplate;

  IriEnumMapperModel(
      {required super.id,
      required super.mappedClass,
      required this.enumValues,
      required super.implementationClass,
      required super.registerGlobally,
      required super.dependencies,
      required super.propertyVariables,
      required super.interpolatedTemplate,
      required super.regexPattern,
      required super.singleMappedValue,
      required super.contextVariables,
      required this.hasFullIriTemplate});

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    final (contextProviders, fields, constructorParameters) =
        resolveDepencencies(context, resolvedDependencies);
    return IriEnumResolvedMapperModel(
        id: id,
        mappedClass: mappedClass,
        enumValues: enumValues,
        implementationClass: implementationClass,
        registerGlobally: registerGlobally,
        mapperFields: fields,
        propertyVariables: propertyVariables
            .map((p) => p.resolve(context, resolvedDependencies))
            .toSet(),
        interpolatedTemplate: interpolatedTemplate,
        regexPattern: regexPattern,
        singleMappedValue:
            singleMappedValue?.resolve(context, resolvedDependencies),
        mapperConstructorParametersNew: constructorParameters,
        contextProviders: contextProviders,
        hasFullIriTemplate: hasFullIriTemplate);
  }
}

/// A mapper for literal terms
sealed class LiteralMapperModel extends GeneratedMapperModel {
  @override
  final MapperType type = MapperType.literal;

  @override
  final MapperId id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  final Code? datatype;

  final String? fromLiteralTermMethod;

  final String? toLiteralTermMethod;

  LiteralMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.dependencies,
    required this.registerGlobally,
    required this.datatype,
    required this.fromLiteralTermMethod,
    required this.toLiteralTermMethod,
  });

  bool get isMethodBased =>
      fromLiteralTermMethod != null && toLiteralTermMethod != null;
}

class LiteralClassMapperModel extends LiteralMapperModel {
  final MappedClassModel mappedClassModel;

  ParameterModel? get rdfValueField =>
      mappedClassModel.allRdfFields.where((p) => p.isRdfValue).singleOrNull;

  ParameterModel? get rdfLanguageField => mappedClassModel.allRdfFields
      .where((p) => p.isRdfLanguageTag)
      .singleOrNull;

  LiteralClassMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.dependencies,
    required super.registerGlobally,
    required super.datatype,
    required this.mappedClassModel,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
  });

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return LiteralClassResolvedMapperModel(
        id: id,
        mappedClass: mappedClass,
        implementationClass: implementationClass,
        registerGlobally: registerGlobally,
        datatype: datatype,
        mappedClassModel:
            mappedClassModel.resolve(context, resolvedDependencies),
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod);
  }
}

class IriPartModel {
  final String name;
  final String dartPropertyName;
  final bool isRdfProperty;

  const IriPartModel({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  IriPartResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return IriPartResolvedModel(
      name: name,
      dartPropertyName: dartPropertyName,
      isRdfProperty: isRdfProperty,
    );
  }
}

class VariableNameModel {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  const VariableNameModel({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  VariableNameResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return VariableNameResolvedModel(
      variableName: variableName,
      placeholder: placeholder,
      isString: isString,
      isMappedValue: isMappedValue,
    );
  }
}

class IriTemplateModel {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameModel> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameModel> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<VariableNameModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  const IriTemplateModel({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
  });

  IriTemplateResolvedModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return IriTemplateResolvedModel(
      template: template,
      variables: variables
          .map((v) => v.resolve(context, resolvedDependencies))
          .toSet(),
      propertyVariables: propertyVariables
          .map((v) => v.resolve(context, resolvedDependencies))
          .toSet(),
      contextVariables: contextVariables
          .map((v) => v.resolve(context, resolvedDependencies))
          .toSet(),
      regexPattern: regexPattern,
      interpolatedTemplate: interpolatedTemplate,
    );
  }
}

class IriModel {
  final IriTemplateModel? template;
  final bool hasFullIriPartTemplate;
  final MapperRefModel? mapper;
  final bool hasMapper;
  final List<IriPartModel> iriMapperParts;

  const IriModel({
    this.template,
    required this.hasFullIriPartTemplate,
    this.mapper,
    this.hasMapper = false,
    required this.iriMapperParts,
  });

  bool get hasTemplate => template != null;

  IriResolvedModel resolve(ValidationContext context,
          Map<MapperId, ResolvedMapperModel> resolvedDependencies) =>
      IriResolvedModel(
          template: template?.resolve(context, resolvedDependencies),
          hasFullIriPartTemplate: hasFullIriPartTemplate,
          mapper: mapper == null
              ? null
              : mapper!.resolve(context, resolvedDependencies),
          hasMapper: hasMapper,
          iriMapperParts: iriMapperParts
              .map((part) => part.resolve(context, resolvedDependencies))
              .toList(growable: false));
}

class MapperRefModel {
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

  const MapperRefModel({
    this.name,
    required this.type,
    this.isNamed = false,
    this.isTypeBased = false,
    this.isInstance = false,
    this.instanceInitializationCode,
  });

  MapperRefResolvedModel resolve(ValidationContext context,
          Map<MapperId, ResolvedMapperModel> resolvedDependencies) =>
      MapperRefResolvedModel(
          type: type,
          name: name,
          isNamed: isNamed,
          isTypeBased: isTypeBased,
          isInstance: isInstance,
          instanceInitializationCode: instanceInitializationCode);
}

class LiteralEnumMapperModel extends LiteralMapperModel {
  final List<EnumValueModel> enumValues;

  LiteralEnumMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.dependencies,
    required super.registerGlobally,
    required super.datatype,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required this.enumValues,
  });

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    return LiteralEnumResolvedMapperModel(
        id: id,
        mappedClass: mappedClass,
        implementationClass: implementationClass,
        registerGlobally: registerGlobally,
        datatype: datatype,
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod,
        enumValues: enumValues);
  }
}

/// A custom mapper (externally provided)
class CustomMapperModel extends MapperModel {
  @override
  final MapperId id;

  @override
  final MapperType type;

  @override
  final Code mappedClass;

  @override
  // Currently, we do not support dependency analysis for custom mappers
  // but at least type based mappers could be supported in the future
  List<DependencyModel> get dependencies => const [];

  @override
  final bool registerGlobally;

  final String? instanceName;
  final Code? instanceInstantiationCode;
  final Code? implementationClass;

  CustomMapperModel(
      {required this.id,
      required this.type,
      required this.mappedClass,
      required this.registerGlobally,
      required this.instanceName,
      required this.instanceInstantiationCode,
      required this.implementationClass});

  @override
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperId, ResolvedMapperModel> resolvedDependencies) {
    // "resolve" the implementation class to the instantiation code
    // for now we only support implementation classes without
    // dependencies, but in future we could support them
    // and then correctly resolve them here.
    final implementationClassCode = implementationClass == null
        ? null
        : Code.combine([implementationClass!, Code.literal('()')]);
    return CustomResolvedMapperModel(
        id: id,
        type: type,
        mappedClass: mappedClass,
        registerGlobally: registerGlobally,
        instanceName: instanceName,
        customMapperInstanceCode:
            implementationClassCode ?? instanceInstantiationCode,
        implementationClass: implementationClass);
  }
}

class DependencyId {
  final String id;
  const DependencyId(this.id);

  static DependencyId generateId() {
    return DependencyId(Uuid().v4().toString());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DependencyId && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DependencyId($id)';
}

// FIXME rename? Or is there a DepencencyResolvedModel?
/// Represents a dependency that a model has
sealed class DependencyModel {
  DependencyId get id;
  const DependencyModel();
}

/// Depends on some mapper, typically to use it during (de-)serialization
class MapperDependency extends DependencyModel {
  final DependencyId id;
  final MapperId mapperId;

  MapperDependency({required this.id, required this.mapperId});
}

/// A generic dependency
class GenericDependency extends DependencyModel {
  final DependencyId id;
  final Code type;
  final String name;

  GenericDependency({required this.id, required this.type, required this.name});
}
