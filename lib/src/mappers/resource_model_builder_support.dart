import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/mappers/iri_model_builder_support.dart';
import 'package:rdf_mapper_generator/src/mappers/mapped_model_builder.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('ResourceModelBuilderSupport');
var contextProviderType = Code.combine([
  Code.coreType('String'),
  Code.literal(' Function()'),
]);

class ResourceModelBuilderSupport {
  /// Builds template data for a global resource mapper.
  static List<MapperModel> buildResourceMapper(ValidationContext context,
      ResourceInfo resourceInfo, String mapperImportUri) {
    if (resourceInfo.annotation.mapper != null) {
      throw Exception(
        'ResourceMapper cannot have a mapper defined in the annotation.',
      );
    }
    UnresolvedInstantiationCodeData unresolved =
        UnresolvedInstantiationCodeData();
    final isGlobalResource = resourceInfo.annotation is RdfGlobalResourceInfo;
    final mappedClassName = resourceInfo.className;
    final implementationClass = Code.type(
        '${mappedClassName.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final termClass = isGlobalResource
        ? Code.type('IriTerm', importUri: importRdfCore)
        : Code.type('BlankNodeTerm', importUri: importRdfCore);

    // Build type IRI expression
    final typeIri = _buildTypeIri(resourceInfo);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategyForResource(resourceInfo, unresolved);

    final mappedClassModel = MappedClassModelBuilder.buildMappedClassModel(
        mappedClassName,
        mapperImportUri,
        resourceInfo.constructors,
        resourceInfo.fields,
        (field) => field.isIriPart || field.isRdfProperty);

    // Build context providers for context variables
    final contextProviders = _buildContextProvidersForResource(resourceInfo);

    final mapperConstructorParameters = _buildMapperConstructorParameters(
        iriStrategy,
        contextProviders,
        resourceInfo,
        mapperImportUri,
        unresolved);

    final resourceMapper = ResourceMapperModel(
        mappedClass: mappedClassName,
        mappedClassModel: mappedClassModel,
        id: MapperId.fromImplementationClass(implementationClass),
        implementationClass: implementationClass,
        termClass: termClass,
        typeIri: typeIri,
        dependencies: const <DependencyModel>[],
        iriStrategy: iriStrategy,
        contextProviders: contextProviders,
        needsReader: resourceInfo.fields.any((p) => p.propertyInfo != null),
        registerGlobally: resourceInfo.annotation.registerGlobally,
        mapperConstructorParametersData: mapperConstructorParameters);

    final propertyMappers = resourceInfo.fields.expand((f) {
      var pi = f.propertyInfo;
      if (pi == null) return const [];
      final iri = pi.annotation.iri;
      if (iri != null && iri.template != null && !iri.isFullIriTemplate) {
        final templateInfo = iri.template!;

        if (!templateInfo.propertyVariables.any((v) => v.name == f.name)) {
          context.addError(
              'Property ${f.name} is not defined in the IRI template: ${templateInfo.template}, but this property is annotated with a template based IriMapping');
        }

        return IriModelBuilderSupport.buildIriMapper(
          context: context,
          mappedClassName: f.type,
          templateInfo: templateInfo,
          iriParts: templateInfo.iriParts,
          mapperClassName: _buildPropertyMapperName(
              mappedClassName, f.name, mapperImportUri),
          registerGlobally: false,
          /* local to the resource mapper */
          mapperImportUri: mapperImportUri,
        );
      }
      return const [];
    });
    return [resourceMapper, ...propertyMappers];
  }

  /// Builds context provider data for context variables.
  static List<ContextProviderData> _buildContextProvidersForIriTemplate(
      IriTemplateInfo? templateInfo) {
    if (templateInfo == null) return [];
    return templateInfo.contextVariableNames.map((variable) {
      final d = _buildVariableNameData(
          variable, false /* not relevant here actually */);
      return ContextProviderData(
        variableName: d.variableName,
        privateFieldName: '_${d.variableName}Provider',
        parameterName: '${d.variableName}Provider',
        placeholder: d.placeholder,
      );
    }).toList();
  }

  static List<ContextProviderData> _buildContextProvidersForResource(
      ResourceInfo resourceInfo) {
    final provides = _collectProvidesVariableNames(resourceInfo.fields);
    final annotation = resourceInfo.annotation;
    final contextProviders = <ContextProviderData>[
      if (annotation is RdfGlobalResourceInfo)
        ..._buildContextProvidersForIriTemplate(annotation.iri?.templateInfo),
      ...resourceInfo.fields.expand((f) {
        var iri = f.propertyInfo?.annotation.iri;
        if (iri == null ||
            iri.template == null ||
            iri.template!.contextVariableNames.isEmpty) {
          return const [];
        }
        var contextVariableNames = iri.template!.contextVariableNames;
        var isOnDemand =
            contextVariableNames.any((v) => provides.contains(v.name));
        return contextVariableNames
            // no context provider needed if we provide the value directly
            .where((variable) => !provides.contains(variable.name))
            .map((variable) {
          final d = _buildVariableNameData(
              variable, f.type == stringType /* is string */);
          return ContextProviderData(
            variableName: d.variableName,
            privateFieldName: '_${d.variableName}Provider',
            parameterName: '${d.variableName}Provider',
            placeholder: d.placeholder,
            isField:
                isOnDemand /* context providers need to be available as fields if the mappers are instantiated on demand */,
          );
        });
      }),
    ];
    // deduplicate context providers by parameterName
    final result = <ContextProviderData>[];
    final seenParameterNames = <String>{};

    for (final provider in contextProviders) {
      if (!seenParameterNames.contains(provider.parameterName)) {
        seenParameterNames.add(provider.parameterName);
        result.add(provider);
      }
    }
    return result;
  }

  static Set<String> _collectProvidesVariableNames(List<FieldInfo> fields) =>
      fields.map((f) => f.provides?.name).nonNulls.toSet();

  static List<ConstructorParameterData> _buildMapperConstructorParameters(
      IriData? iriStrategy,
      List<ContextProviderData> contextProviders,
      ResourceInfo resourceInfo,
      String mapperImportUri,
      UnresolvedInstantiationCodeData unresolved) {
    final provides = _collectProvidesVariableNames(resourceInfo.fields);
    final List<ConstructorParameterData> mapperConstructorParameters = [
      if (iriStrategy?.hasMapper ?? false)
        ConstructorParameterData(
            fieldName: '_iriMapper',
            parameterName:
                iriStrategy!.mapper!.isNamed && iriStrategy.mapper!.name != null
                    ? iriStrategy.mapper!.name!
                    : 'iriMapper',
            type: iriStrategy.mapper!.type,
            defaultValue: null,
            isLate: false),
      ...contextProviders.map((provider) => ConstructorParameterData(
          fieldName: provider.privateFieldName,
          parameterName: provider.parameterName,
          isLate: false,
          type: contextProviderType,
          defaultValue: null,
          isField: provider.isField)),
      ...resourceInfo.fields.expand((f) {
        final iri = f.propertyInfo?.annotation.iri;
        final literal = f.propertyInfo?.annotation.literal;
        final globalResourceMapper =
            f.propertyInfo?.annotation.globalResource?.mapper;
        final localResourceMapper =
            f.propertyInfo?.annotation.localResource?.mapper;
        return [
          if (iri != null)
            if (iri.mapper != null)
              _mappingToConstructorParameter(
                  f, iri.mapper!, 'IriTermMapper', unresolved)
            else if (iri.template != null && !iri.isFullIriTemplate)
              ..._propertyIriTemplateMapperConstructorParameter(
                  f,
                  'IriTermMapper',
                  resourceInfo.className,
                  mapperImportUri,
                  iri.template!,
                  provides,
                  unresolved)
            else if (iri.isFullIriTemplate)
              _constructorParameterWithValue(
                  f.name,
                  f,
                  'IriTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    Code.type('IriFullMapper', importUri: mapperImportUri),
                    Code.literal('()')
                  ])),
          if (literal != null)
            if (literal.mapper != null)
              _mappingToConstructorParameter(
                  f, literal.mapper!, 'LiteralTermMapper', unresolved)
            else if (literal.datatype != null)
              _constructorParameterWithValue(
                  f.name,
                  f,
                  'LiteralTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    codeGeneric1(
                        Code.type('DatatypeOverrideMapper',
                            importUri: mapperImportUri),
                        f.type),
                    Code.literal('('),
                    literal.datatype!.code,
                    Code.literal(')')
                  ]))
            else if (literal.language != null)
              _constructorParameterWithValue(
                  f.name,
                  f,
                  'LiteralTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    codeGeneric1(
                        Code.type('LanguageOverrideMapper',
                            importUri: mapperImportUri),
                        f.type),
                    Code.literal("('${literal.language}')"),
                  ])),
          if (globalResourceMapper != null)
            _mappingToConstructorParameter(
                f, globalResourceMapper, 'GlobalResourceMapper', unresolved),
          if (localResourceMapper != null)
            _mappingToConstructorParameter(
                f, localResourceMapper, 'LocalResourceMapper', unresolved),
        ];
      })
    ];
    return mapperConstructorParameters;
  }

  static List<ConstructorParameterData>
      _propertyIriTemplateMapperConstructorParameter(
          FieldInfo f,
          String mapperInterface,
          Code className,
          String mapperImportUri,
          IriTemplateInfo iriTemplateInfo,
          Set<String> provides,
          UnresolvedInstantiationCodeData unresolved) {
    final isLate = iriTemplateInfo.contextVariables.isNotEmpty;
    final isOnDemand =
        iriTemplateInfo.contextVariables.any((v) => provides.contains(v));
    if (isOnDemand) {
      return const [];
    }
    final generatedMapperName =
        _buildPropertyMapperName(className, f.name, mapperImportUri);
    /*
    Code? defaultValue = null;
    if (isLate) {
      // default value actually needs to be set to the constructor
      // call of the mapper
      defaultValue = Code.combine([
        generatedMapperName,
        Code.literal('('),
        ...iriTemplateInfo.contextVariables
            .map((name) => Code.literal('${name}Provider: ${name}Provider, ')),
        Code.literal(')')
      ]);
    } else {
      defaultValue = Code.combine(
          [Code.literal('const '), generatedMapperName, Code.literal('()')]);
    }
    */
    return [
      ConstructorParameterData(
          fieldName: _buildMapperFieldName(f.name),
          parameterName: f.name + 'Mapper',
          type: _buildMapperInterfaceTypeForProperty(
              Code.type(mapperInterface, importUri: importRdfMapper), f),
          isLate: isLate,
          defaultValue:
              ResolvableInstantiationCodeData(generatedMapperName, unresolved))
    ];
  }

  static String _buildMapperFieldName(String fieldName) =>
      '_' + fieldName + 'Mapper';

  static ConstructorParameterData _constructorParameterWithValue(
      String fieldName, FieldInfo f, String mapperInterfaceType, Code value) {
    return ConstructorParameterData(
        fieldName: _buildMapperFieldName(fieldName),
        parameterName: fieldName + 'Mapper',
        type: _buildMapperInterfaceTypeForProperty(
            Code.type(mapperInterfaceType, importUri: importRdfMapper), f),
        isLate: false,
        defaultValue: ResolvableInstantiationCodeData.resolved(value));
  }

  /// Builds the mapper interface type, considering collection types
  static Code _buildMapperInterfaceTypeForProperty(
      Code mapperInterface, FieldInfo field) {
    final propertyInfo = field.propertyInfo;
    if (propertyInfo == null) {
      return codeGeneric1(mapperInterface, field.typeNonNull);
    }

    final collectionInfo = propertyInfo.collectionInfo;
    if (collectionInfo.isCollection) {
      // For collections, the mapper type should be for the element type
      if (collectionInfo.isMap &&
          collectionInfo.keyTypeCode != null &&
          collectionInfo.valueTypeCode != null) {
        // For maps, use MapEntry<K,V> as the element type
        final mapEntryType = codeGeneric2(Code.type('MapEntry'),
            collectionInfo.keyTypeCode!, collectionInfo.valueTypeCode!);
        return codeGeneric1(mapperInterface, mapEntryType);
      } else if (collectionInfo.elementTypeCode != null) {
        // For List/Set, use the element type
        return codeGeneric1(mapperInterface, collectionInfo.elementTypeCode!);
      }
    }

    // Default case: not a collection or collection not handled specially
    return codeGeneric1(mapperInterface, field.typeNonNull);
  }

  static ConstructorParameterData _mappingToConstructorParameter(
      FieldInfo f,
      MapperRefInfo<dynamic> iriMapper,
      String mapperInterface,
      UnresolvedInstantiationCodeData unresolved) {
    return ConstructorParameterData(
        fieldName: _buildMapperFieldName(f.name),
        parameterName: iriMapper.name ?? f.name + 'Mapper',
        type: _buildMapperInterfaceTypeForProperty(
            Code.type(mapperInterface, importUri: importRdfMapper), f),
        isLate: false,
        defaultValue: iriMapper.name == null
            ? _mapperRefInfoToCode(iriMapper, unresolved)
            : null);
  }

  static ResolvableInstantiationCodeData _mapperRefInfoToCode(
      MapperRefInfo mapper, UnresolvedInstantiationCodeData unresolved) {
    var customMapperType = mapper.type;
    if (customMapperType != null) {
      return ResolvableInstantiationCodeData(customMapperType.name, unresolved);
    }
    var customMapperName = mapper.name;
    var customMapperInstance =
        mapper.instance == null ? null : toCode(mapper.instance);
    return ResolvableInstantiationCodeData.resolved(_customMapperCode(
      customMapperInstance,
      customMapperName,
    ));
  }

  static Code _customMapperCode(
      Code? instanceInitializationCode, String? name) {
    final code = instanceInitializationCode ??
        (name == null ? null : Code.literal(name));
    if (code == null) {
      throw ArgumentError('No valid code found for IRI mapper ');
    }
    return code;
  }

  static Code _buildPropertyMapperName(
      Code className, String fieldName, String mapperImportUri) {
    return Code.type(
        '${className.codeWithoutAlias}${_capitalizeFirstLetter(fieldName)}Mapper',
        importUri: mapperImportUri);
  }

  static String _capitalizeFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  /// Builds the type IRI expression.
  static Code? _buildTypeIri(ResourceInfo resourceInfo) {
    final classIriInfo = resourceInfo.annotation.classIri;
    return classIriInfo?.code;
  }

  static IriData? _buildIriStrategyForResource(
      ResourceInfo resourceInfo, UnresolvedInstantiationCodeData unresolved) {
    final annotation = resourceInfo.annotation;
    if (annotation is! RdfGlobalResourceInfo) {
      return null;
    }
    final iriStrategy = annotation.iri;
    if (iriStrategy == null) {
      throw Exception(
        'Trying to generate a mapper for resource ${resourceInfo.className}, but iri strategy is not defined. This should not be possible.',
      );
    }
    return _buildIriData(
        iriStrategy.template,
        iriStrategy.mapper,
        iriStrategy.iriMapperType?.type,
        iriStrategy.iriMapperType?.parts,
        iriStrategy.templateInfo,
        resourceInfo.fields,
        unresolved);
  }

  /// Builds IRI strategy data.
  static IriData? _buildIriData(
      String? template,
      MapperRefInfo<IriTermMapper>? mapper,
      Code? type,
      List<IriPartInfo>? iriParts,
      IriTemplateInfo? templateInfo,
      List<FieldInfo>? fields,
      UnresolvedInstantiationCodeData unresolved) {
    MapperRefData? mapperRef;
    if (mapper != null && type != null) {
      if (mapper.name != null) {
        mapperRef = MapperRefData(
          name: mapper.name,
          isNamed: true,
          type: type,
        );
      } else if (mapper.type != null) {
        final typeValue = mapper.type;
        if (typeValue != null) {
          mapperRef = MapperRefData(
            instanceInitializationCode:
                ResolvableInstantiationCodeData(typeValue.name, unresolved),
            isTypeBased: true,
            type: type,
          );
        } else {
          _log.warning('Mapper type is not based on a type: $mapper');
        }
      } else if (mapper.instance != null) {
        mapperRef = MapperRefData(
          isInstance: true,
          type: type,
          instanceInitializationCode:
              ResolvableInstantiationCodeData.resolved(toCode(mapper.instance)),
        );
      }
    }
    final rdfPropertyFields = fields
        ?.where((f) => f.propertyInfo != null)
        .map((f) => f.propertyInfo!.name)
        .toSet();
    final iriMapperParts = iriParts
            ?.map((p) => IriPartData(
                  name: p.name,
                  dartPropertyName: p.dartPropertyName,
                  isRdfProperty:
                      rdfPropertyFields?.contains(p.dartPropertyName) ?? false,
                ))
            .toList() ??
        [];
    return IriData(
      template: template == null
          ? null
          : _buildTemplateData(templateInfo!, fields ?? []),
      hasFullIriPartTemplate:
          IriModelBuilderSupport.hasFullIriPartTemplate(iriParts, template),
      mapper: mapperRef,
      hasMapper: mapperRef != null,
      iriMapperParts: iriMapperParts,
    );
  }

  static IriTemplateData _buildTemplateData(
      IriTemplateInfo iriTemplateInfo, List<FieldInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: stringType == field.type,
    };
    VariableNameData buildVariableNameData(VariableName variable) =>
        _buildVariableNameData(
            variable, isStringByFieldName[variable.dartPropertyName] ?? false);
    return IriTemplateData(
      template: iriTemplateInfo.template,
      propertyVariables:
          iriTemplateInfo.propertyVariables.map(buildVariableNameData).toSet(),
      contextVariables: iriTemplateInfo.contextVariableNames
          .map(buildVariableNameData)
          .toSet(),
      variables:
          iriTemplateInfo.variableNames.map(buildVariableNameData).toSet(),
      regexPattern:
          '^${buildRegexPattern(iriTemplateInfo.template, iriTemplateInfo.variableNames)}\\\$',
      interpolatedTemplate:
          IriModelBuilderSupport.buildInterpolatedTemplate(iriTemplateInfo),
    );
  }

  static VariableNameData _buildVariableNameData(
      VariableName variable, bool isString) {
    return VariableNameData(
      isString: isString,
      variableName: variable.dartPropertyName,
      isMappedValue: variable.isMappedValue,
      placeholder:
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}',
    );
  }
}
