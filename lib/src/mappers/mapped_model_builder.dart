import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart'
    hide MapperRef;
import 'package:rdf_mapper_generator/src/mappers/iri_model_builder_support.dart';
import 'package:rdf_mapper_generator/src/mappers/util.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

import '../processors/models/mapper_info.dart';
import 'mapper_model.dart';

class MappedClassModelBuilder {
  static MappedClassModel buildMappedClassModel(
      ValidationContext context,
      Code mappedClass,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields) {
    final constructor = constructors.firstOrNull;
    final properties = _buildPropertyData(context, mappedClass, fields,
        constructor?.parameters ?? const [], mapperImportUri);

    return MappedClassModel(
      constructorName: constructor?.name,
      className: mappedClass,
      properties: properties,
    );
  }

  static List<PropertyModel> _buildPropertyData(
      ValidationContext context,
      Code mappedClass,
      List<FieldInfo> fields,
      List<ParameterInfo> constructorParameters,
      String mapperImportUri) {
    final fieldsByPropertyName = {for (var field in fields) field.name: field};
    final constructorParametersByName = {
      for (var param in constructorParameters) param.name: param
    };
    final allPropertyNames = {
      ...fieldsByPropertyName.keys,
      ...constructorParametersByName.keys,
    };
    return allPropertyNames.map((propertyName) {
      final f = fieldsByPropertyName[propertyName];
      final c = constructorParametersByName[propertyName];
      final propertyInfo = f?.propertyInfo ?? c?.propertyInfo;
      // Determine collection information and methods
      final collectionInfo = propertyInfo?.collectionInfo;

      var dartType = f?.type ?? c?.type ?? const Code.literal('dynamic');
      var dartTypeNonNull = f?.typeNonNull ?? dartType;

      final iri = propertyInfo?.annotation.iri;
      final literal = propertyInfo?.annotation.literal;
      final globalResource = propertyInfo?.annotation.globalResource;
      final localResource = propertyInfo?.annotation.localResource;

      return PropertyModel(
        propertyName: propertyName,
        dartType: dartType,
        isRdfProperty: propertyInfo != null,
        isRdfValue: f?.isRdfValue ?? c?.isRdfValue ?? false,
        isRdfLanguageTag: f?.isRdfLanguageTag ?? c?.isRdfLanguageTag ?? false,
        isIriPart: f?.iriPart != null,
        iriPartName: f?.iriPart?.name,
        isProvides: f?.provides != null,
        providesVariableName: f?.provides?.name,
        predicate: propertyInfo?.annotation.predicate.code,
        include: propertyInfo?.annotation.include ?? false,
        defaultValue: toCode(propertyInfo?.annotation.defaultValue),
        hasDefaultValue: propertyInfo?.annotation.defaultValue != null,
        includeDefaultsInSerialization:
            propertyInfo?.annotation.includeDefaultsInSerialization ?? false,

        // FIXME: move to CollectionModel?
        isCollection: collectionInfo?.isCollection ?? false,
        isMap: collectionInfo?.isMap ?? false,
        isList: collectionInfo?.isList ?? false,
        isSet: collectionInfo?.isSet ?? false,
        constructorParameterName: c?.name,
        isNamedConstructorParameter: c?.isNamed ?? false,
        isRequired:
            c?.isRequired ?? false, // constructor parameter required, actually

        isField: f != null,
        isFieldFinal: f?.isFinal ?? false,
        isFieldLate: f?.isLate ?? false,
        isFieldStatic: f?.isStatic ?? false,
        isFieldSynthetic: f?.isSynthetic ?? false,
        isFieldNullable: !(f?.isRequired ?? true),

        collectionInfo: CollectionModel(
            isCollection: collectionInfo?.isCollection ?? false,
            isMap: collectionInfo?.isMap ?? false,
            isIterable: collectionInfo?.isIterable ?? false,
            elementTypeCode: collectionInfo?.elementTypeCode,
            mapValueTypeCode: collectionInfo?.valueTypeCode,
            mapKeyTypeCode: collectionInfo?.keyTypeCode),

        collectionType:
            propertyInfo?.annotation.collection ?? RdfCollectionType.none,

        iriMapping: iri == null
            ? null
            : buildIriMapping(context, mappedClass, mapperImportUri, iri,
                propertyInfo!, fields, dartTypeNonNull, propertyName),
        literalMapping: literal == null
            ? null
            : buildLiteralMapping(
                literal, propertyInfo!, dartTypeNonNull, propertyName),
        globalResourceMapping: globalResource == null
            ? null
            : buildGlobalResourceMapping(
                globalResource, propertyInfo!, dartTypeNonNull, propertyName),
        localResourceMapping: localResource == null
            ? null
            : buildLocalResourceMapping(
                localResource, propertyInfo!, dartTypeNonNull, propertyName),
      );
    }).toList();
  }

  static LocalResourceMappingModel buildLocalResourceMapping(
      LocalResourceMappingInfo localResource,
      PropertyInfo propertyInfo,
      Code dartTypeNonNull,
      String propertyName) {
    return LocalResourceMappingModel(
        hasMapper: true,
        dependency: createMapperDependency(
            propertyInfo.collectionInfo,
            localResource.mapper!,
            dartTypeNonNull,
            propertyName,
            'LocalResourceMapper'));
  }

  static GlobalResourceMappingModel buildGlobalResourceMapping(
      GlobalResourceMappingInfo globalResource,
      PropertyInfo propertyInfo,
      Code dartTypeNonNull,
      String propertyName) {
    return GlobalResourceMappingModel(
        hasMapper: true,
        dependency: createMapperDependency(
            propertyInfo.collectionInfo,
            globalResource.mapper!,
            dartTypeNonNull,
            propertyName,
            'GlobalResourceMapper'));
  }

  static LiteralMappingModel? buildLiteralMapping(LiteralMappingInfo literal,
      PropertyInfo propertyInfo, Code dartTypeNonNull, String propertyName) {
    if (literal.mapper == null &&
        literal.datatype == null &&
        literal.language == null) {
      return null;
    }

    final MapperRef mapperRef;
    if (literal.mapper != null) {
      mapperRef =
          IriModelBuilderSupport.mapperRefInfoToMapperRef(literal.mapper!);
    } else if (literal.datatype != null) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        codeGeneric1(
            Code.type('DatatypeOverrideMapper', importUri: importRdfMapper),
            dartTypeNonNull),
        Code.paramsList([literal.datatype!.code]),
      ]));
    } else if (literal.language != null) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        codeGeneric1(
            Code.type('LanguageOverrideMapper', importUri: importRdfMapper),
            dartTypeNonNull),
        Code.paramsList([Code.literal("'${literal.language!}'")])
      ]));
    } else {
      throw Exception(
          'LiteralMappingInfo must have either a mapper, datatype or language defined.');
    }
    final dependency = DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type('LiteralTermMapper', importUri: importRdfMapper),
          propertyInfo.collectionInfo,
          dartTypeNonNull),
      propertyName,
      mapperRef,
    );

    return LiteralMappingModel(
        hasMapper: literal.mapper != null, dependency: dependency);
  }

  static IriMappingModel? buildIriMapping(
      ValidationContext context,
      Code mappedClassName,
      String mapperImportUri,
      IriMappingInfo iri,
      PropertyInfo propertyInfo,
      List<FieldInfo> fields,
      Code dartTypeNonNull,
      String propertyName) {
    if (iri.mapper == null && iri.template == null) {
      return null;
    }

    final MapperRef mapperRef;
    final List<MapperModel> extraMappers = [];
    if (iri.mapper != null) {
      mapperRef = IriModelBuilderSupport.mapperRefInfoToMapperRef(iri.mapper!);
    } else if (iri.template != null && !iri.isFullIriTemplate) {
      if (!iri.template!.propertyVariables.any((v) => v.name == propertyName)) {
        context.addError(
            'Property ${propertyName} is not defined in the IRI template: ${iri.template!.template}, but this property is annotated with a template based IriMapping');
      }
      final Code generatedMapperClassName = _buildPropertyMapperClassName(
          mappedClassName, propertyName, mapperImportUri);
      mapperRef = MapperRef.fromImplementationClass(generatedMapperClassName);
      final generatedMapper = IriModelBuilderSupport.buildIriMapper(
        context: context,
        mappedClassName: dartTypeNonNull,
        templateInfo: iri.template!,
        iriParts: iri.template!.iriParts,
        mapperClassName: generatedMapperClassName,
        registerGlobally: false,
        /* local to the resource mapper */
        mapperImportUri: mapperImportUri,
      );
      extraMappers.addAll(generatedMapper);
    } else if (iri.isFullIriTemplate) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        Code.type('IriFullMapper', importUri: importRdfMapper),
        Code.literal('()')
      ]));
    } else {
      throw Exception(
          'IriMappingInfo must have either a mapper or a template defined.');
    }
    final dependency = DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type('IriTermMapper', importUri: importRdfMapper),
          propertyInfo.collectionInfo,
          dartTypeNonNull),
      propertyName,
      mapperRef,
    );

    return IriMappingModel(
        hasMapper: iri.mapper != null,
        dependency: dependency,
        extraMappers: extraMappers);
  }

  static String _capitalizeFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  static Code _buildPropertyMapperClassName(
      Code className, String fieldName, String mapperImportUri) {
    return Code.type(
        '${className.codeWithoutAlias}${_capitalizeFirstLetter(fieldName)}Mapper',
        importUri: mapperImportUri);
  }

  static MapperDependency createMapperDependency(
      CollectionInfo? collectionInfo,
      MapperRefInfo mapper,
      Code dartTypeNonNull,
      String propertyName,
      String interfaceTypeName) {
    return DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type(interfaceTypeName, importUri: importRdfMapper),
          collectionInfo,
          dartTypeNonNull),
      propertyName,
      IriModelBuilderSupport.mapperRefInfoToMapperRef(mapper),
    );
  }
}
