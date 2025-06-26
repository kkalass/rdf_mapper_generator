library;

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
  List<ConstructorParameterModel> get mapperConstructorParameters;

  List<FieldModel> get mapperFields;
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

  final MappedClassModel mappedClassModel;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  final Code? typeIri;

  final Code termClass;

  /// IRI strategy information
  final IriData? iriStrategy;

  /// Context variable providers needed for IRI generation
  /// FIXME convert from model?
  @override
  List<ConstructorParameterModel> get mapperConstructorParameters => const [];
  @override
  // FIXME: implement mapperFields
  List<FieldModel> get mapperFields => const [];
  final List<ConstructorParameterData> mapperConstructorParametersData;
  final List<ContextProviderData> contextProviders;
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
    required this.mapperConstructorParametersData,
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
        iriStrategy: iriStrategy,
        contextProviders: contextProviders,
        constructorParameters: mappedClassModel.constructorParameters,
        needsReader: needsReader,
        properties: mappedClassModel.properties,
        nonConstructorFields: mappedClassModel.nonConstructorRdfFields,
        mapperConstructorParameters: mapperConstructorParametersData);
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

  /// FIXME partially wrong layer
  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameData> propertyVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  final VariableNameData? singleMappedValue;

  /// FIXME: wrong layer / wrong abstraction
  final List<ContextProviderData> contextProviders;

  final List<ConstructorParameterModel> mapperConstructorParameters;

  @override
  final List<FieldModel> mapperFields;

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
    required this.mapperConstructorParameters,
    required this.mapperFields,
  });
}

class IriClassResolvedMapperModel extends IriResolvedMapperModel {
  final MappedClassModel mappedClassModel;
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
    required super.mapperConstructorParameters,
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
        propertyVariables: propertyVariables,
        interpolatedTemplate: interpolatedTemplate,
        regexPattern: regexPattern,
        contextProviders: contextProviders,
        constructorParameters: mappedClassModel.constructorParameters,
        nonConstructorFields: mappedClassModel.nonConstructorRdfFields,
        registerGlobally: registerGlobally,
        singleMappedValue: singleMappedValue);
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
    required super.mapperConstructorParameters,
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
      contextProviders: contextProviders,
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
  List<ConstructorParameterModel> get mapperConstructorParameters => const [];

  @override
  List<FieldModel> get mapperFields => const [];

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
  final MappedClassModel mappedClassModel;

  ParameterData? get rdfValueField =>
      mappedClassModel.allRdfFields.where((p) => p.isRdfValue).singleOrNull;

  ParameterData? get rdfLanguageField => mappedClassModel.allRdfFields
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
          constructorParameters: mappedClassModel.constructorParameters,
          nonConstructorFields: mappedClassModel.nonConstructorRdfFields,
          registerGlobally: registerGlobally,
          properties: mappedClassModel.properties,
          rdfValue: rdfValueField,
          rdfLanguageTag: rdfLanguageField);
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

class ConstructorParameterModel {
  final Code type;
  final String paramName;
  final String? associatedFieldName;
  final DependencyModel? dependency;

  ConstructorParameterModel(
      {required this.type,
      required this.paramName,
      required this.associatedFieldName,
      required this.dependency});
}

class FieldModel {
  final String name;
  final Code type;

  FieldModel({required this.name, required this.type});
}
