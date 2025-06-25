import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('GlobalResourceDataBuilder');

/// Builds template data from processed resource information.
class DataBuilder {
  static Code customMapperCode(
      Code? implementationType, Code? instanceInitializationCode, String? name,
      {bool constContext = false}) {
    Code? code;
    if (implementationType != null) {
      // instantiate the constructor with empty parameters
      code = Code.combine([
        if (constContext) Code.literal('const '),
        implementationType,
        Code.literal('()')
      ]);
    } else if (instanceInitializationCode != null) {
      code = instanceInitializationCode;
    }
    if (code == null && name != null) {
      code = Code.literal(name);
    }
    if (code == null) {
      throw ArgumentError('No valid code found for IRI mapper ');
    }
    return code;
  }

  static Code mapperRefInfoToCode(MapperRefInfo mapper,
      {bool constContext = false}) {
    var customMapperName = mapper.name;
    var customMapperType =
        mapper.type == null ? null : typeToCode(mapper.type!.toTypeValue()!);
    var customMapperInstance =
        mapper.instance == null ? null : toCode(mapper.instance);
    return customMapperCode(
        customMapperType, customMapperInstance, customMapperName,
        constContext: constContext);
  }

  static List<MappableClassMapperTemplateData> buildCustomMapper(
      ValidationContext context,
      Code className,
      BaseMappingAnnotationInfo annotation) {
    assert(annotation.mapper != null);
    final mapper = annotation.mapper!;
    Code mapperInterfaceType =
        _buildMapperInterfaceTypeFromBaseMapper(annotation, className);
    // Build imports

    var customMapperName = mapper.name;
    var customMapperType =
        mapper.type == null ? null : typeToCode(mapper.type!.toTypeValue()!);
    var customMapperInstance =
        mapper.instance == null ? null : toCode(mapper.instance);
    if (customMapperName == null &&
        customMapperType == null &&
        customMapperInstance == null) {
      context.addError(
        'Custom mapper must have either a name or a type defined in the annotation.',
      );
    }
    return [
      CustomMapperTemplateData(
        className: className,
        mapperInterfaceType: mapperInterfaceType,
        customMapperName: customMapperName,
        customMapperType: customMapperType,
        customMapperInstance: customMapperInstance,
        registerGlobally: annotation.registerGlobally,
      )
    ];
  }

  static Code _buildMapperInterfaceTypeFromBaseMapper(
      BaseMappingAnnotationInfo<dynamic> annotation, Code className) {
    final mapperInterface = _mapperInterfaceNameFor(annotation);
    return _buildMapperInterfaceType(mapperInterface, className);
  }

  static Code _buildMapperInterfaceType(Code mapperInterface, Code className) {
    final mapperInterfaceType = Code.combine([
      mapperInterface,
      Code.literal('<'),
      className,
      Code.literal('>'),
    ]);
    return mapperInterfaceType;
  }

  static Code _mapperInterfaceNameFor(
      BaseMappingAnnotationInfo<dynamic> annotation) {
    return Code.type(
        switch (annotation) {
          RdfGlobalResourceInfo _ => 'GlobalResourceMapper',
          RdfLocalResourceInfo _ => 'LocalResourceMapper',
          RdfIriInfo _ => 'IriTermMapper',
          RdfLiteralInfo _ => 'LiteralTermMapper',
        },
        importUri: importRdfMapper);
  }

  /// Builds template data for a global resource mapper.
  static List<MappableClassMapperTemplateData> buildResourceMapper(
      ValidationContext context,
      ResourceInfo resourceInfo,
      String mapperImportUri) {
    if (resourceInfo.annotation.mapper != null) {
      throw Exception(
        'ResourceMapper cannot have a mapper defined in the annotation.',
      );
    }

    final isGlobalResource = resourceInfo.annotation is RdfGlobalResourceInfo;
    final className = resourceInfo.className;
    final mapperClassName = Code.type('${className.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final mapperInterfaceName =
        _mapperInterfaceNameFor(resourceInfo.annotation);
    final termClass = isGlobalResource
        ? Code.type('IriTerm', importUri: importRdfCore)
        : Code.type('BlankNodeTerm', importUri: importRdfCore);

    // Build type IRI expression
    final typeIri = _buildTypeIri(resourceInfo);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategyForResource(resourceInfo);

    // Build context providers for context variables
    final contextProviders = _buildContextProvidersForResource(resourceInfo);

    // Build constructor parameters
    final resourceConstructorParameters = _buildConstructorParameters(className,
        resourceInfo.constructors, resourceInfo.fields, mapperImportUri);
    final nonConstructorFields = _buildNonConstructorFields(
            className,
            resourceConstructorParameters,
            resourceInfo.fields,
            iriStrategy,
            mapperImportUri)
        .where((p) => p.isIriPart || p.isRdfProperty)
        .toList();

    final properties =
        _buildPropertyData(className, resourceInfo.fields, mapperImportUri);
    final mapperConstructorParameters = buildMapperConstructorParameters(
        iriStrategy, contextProviders, resourceInfo, mapperImportUri);

    final resourceMapper = ResourceMapperTemplateData(
        className: className,
        mapperClassName: mapperClassName,
        mapperInterfaceName: mapperInterfaceName,
        termClass: termClass,
        typeIri: typeIri,
        iriStrategy: iriStrategy,
        contextProviders: contextProviders,
        constructorParameters: resourceConstructorParameters,
        nonConstructorFields: nonConstructorFields,
        needsReader: resourceInfo.fields.any((p) => p.propertyInfo != null),
        registerGlobally: resourceInfo.annotation.registerGlobally,
        properties: properties,
        mapperConstructorParameters: mapperConstructorParameters);

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
        return _buildIriMapper(
            className: f.type,
            templateInfo: templateInfo,
            iriParts: templateInfo.iriParts,
            mapperClassName:
                buildPropertyMapperName(className, f.name, mapperImportUri),
            registerGlobally: false,
            /* local to the resource mapper */
            mapperImportUri: mapperImportUri);
      }
      return const [];
    });
    return [resourceMapper, ...propertyMappers];
  }

  static Code buildPropertyMapperName(
      Code className, String fieldName, String mapperImportUri) {
    return Code.type(
        '${className.codeWithoutAlias}${_capitalizeFirstLetter(fieldName)}Mapper',
        importUri: mapperImportUri);
  }

  static String _capitalizeFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  static List<ConstructorParameterData> buildMapperConstructorParameters(
      IriData? iriStrategy,
      List<ContextProviderData> contextProviders,
      ResourceInfo resourceInfo,
      String mapperImportUri) {
    final provides = collectProvidesVariableNames(resourceInfo.fields);
    final List<ConstructorParameterData> mapperConstructorParameters = [
      if (iriStrategy?.hasMapper ?? false)
        ConstructorParameterData(
            fieldName: '_iriMapper',
            parameterName: 'iriMapper',
            type: iriStrategy!.mapper!.type,
            defaultValue: null,
            isLate: false),
      ...contextProviders.map((provider) => ConstructorParameterData(
          fieldName: provider.privateFieldName,
          parameterName: provider.parameterName,
          isLate: false,
          type: Code.combine([
            Code.coreType('String'),
            Code.literal(' Function()'),
          ]),
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
              mappingToConstructorParameter(f, iri.mapper!, 'IriTermMapper')
            else if (iri.template != null && !iri.isFullIriTemplate)
              ..._propertyIriTemplateMapperConstructorParameter(
                  f,
                  'IriTermMapper',
                  resourceInfo.className,
                  mapperImportUri,
                  iri.template!,
                  provides)
            else if (iri.isFullIriTemplate)
              constructorParameterWithValue(
                  f.name,
                  f.type,
                  'IriTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    Code.type('IriFullMapper', importUri: mapperImportUri),
                    Code.literal('()')
                  ])),
          if (literal != null)
            if (literal.mapper != null)
              mappingToConstructorParameter(
                  f, literal.mapper!, 'LiteralTermMapper')
            else if (literal.datatype != null)
              constructorParameterWithValue(
                  f.name,
                  f.type,
                  'LiteralTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    Code.type('DatatypeOverrideMapper',
                        importUri: mapperImportUri),
                    Code.literal('<'),
                    f.type,
                    Code.literal('>'),
                    Code.literal('('),
                    literal.datatype!.code,
                    Code.literal(')')
                  ]))
            else if (literal.language != null)
              constructorParameterWithValue(
                  f.name,
                  f.type,
                  'LiteralTermMapper',
                  Code.combine([
                    Code.literal('const '),
                    Code.type('LanguageOverrideMapper',
                        importUri: mapperImportUri),
                    Code.literal('<'),
                    f.type,
                    Code.literal('>'),
                    Code.literal("('${literal.language}')"),
                  ])),
          if (globalResourceMapper != null)
            mappingToConstructorParameter(
                f, globalResourceMapper, 'GlobalResourceMapper'),
          if (localResourceMapper != null)
            mappingToConstructorParameter(
                f, localResourceMapper, 'LocalResourceMapper'),
        ];
      })
    ];
    return mapperConstructorParameters;
  }

  static ConstructorParameterData constructorParameterWithValue(
      String fieldName, Code type, String mapperInterfaceType, Code value) {
    return ConstructorParameterData(
        fieldName: _buildMapperFieldName(fieldName),
        parameterName: fieldName + 'Mapper',
        type: _buildMapperInterfaceType(
            Code.type(mapperInterfaceType, importUri: importRdfMapper), type),
        isLate: false,
        defaultValue: value);
  }

  static ConstructorParameterData mappingToConstructorParameter(
      FieldInfo f, MapperRefInfo<dynamic> iriMapper, String mapperInterface) {
    return ConstructorParameterData(
        fieldName: _buildMapperFieldName(f.name),
        parameterName: iriMapper.name ?? f.name + 'Mapper',
        type: _buildMapperInterfaceType(
            Code.type(mapperInterface, importUri: importRdfMapper), f.type),
        isLate: false,
        defaultValue: iriMapper.name == null
            ? mapperRefInfoToCode(iriMapper, constContext: true)
            : null);
  }

  static List<ConstructorParameterData>
      _propertyIriTemplateMapperConstructorParameter(
          FieldInfo f,
          String mapperInterface,
          Code className,
          String mapperImportUri,
          IriTemplateInfo iriTemplateInfo,
          Set<String> provides) {
    final isLate = iriTemplateInfo.contextVariables.isNotEmpty;
    final isOnDemand =
        iriTemplateInfo.contextVariables.any((v) => provides.contains(v));
    if (isOnDemand) {
      return const [];
    }
    final generatedMapperName =
        buildPropertyMapperName(className, f.name, mapperImportUri);
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
    return [
      ConstructorParameterData(
          fieldName: _buildMapperFieldName(f.name),
          parameterName: f.name + 'Mapper',
          type: _buildMapperInterfaceType(
              Code.type(mapperInterface, importUri: importRdfMapper), f.type),
          isLate: isLate,
          defaultValue: defaultValue)
    ];
  }

  static String _buildMapperFieldName(String fieldName) =>
      '_' + fieldName + 'Mapper';

  static List<MappableClassMapperTemplateData> buildLiteralMapper(
      ValidationContext context,
      LiteralInfo resourceInfo,
      String mapperImportUri) {
    final annotation = resourceInfo.annotation;
    if (annotation.mapper != null) {
      throw Exception(
        'LiteralMapper cannot have a mapper defined in the annotation.',
      );
    }
    final className = resourceInfo.className;
    final mapperClassName = Code.type('${className.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final mapperInterfaceName = _mapperInterfaceNameFor(annotation);
    final datatype = annotation.datatype?.code;
    final fromLiteralTermMethod = annotation.fromLiteralTermMethod;
    final toLiteralTermMethod = annotation.toLiteralTermMethod;
    final isMethodBased =
        fromLiteralTermMethod != null || toLiteralTermMethod != null;

    // Build constructor parameters
    final constructorParameters = _buildConstructorParameters(className,
        resourceInfo.constructors, resourceInfo.fields, mapperImportUri);

    // Collect non-constructor fields that are RDF value or language tag fields
    final allNonConstructorFields = _buildNonConstructorFields(className,
        constructorParameters, resourceInfo.fields, null, mapperImportUri);
    final nonConstructorFields = allNonConstructorFields
        .where((field) => field.isRdfValue || field.isRdfLanguageTag)
        .toList();

    // Combine constructor and non-constructor RDF fields for validation
    final constructorRdfFields = constructorParameters
        .where((p) => p.isRdfValue || p.isRdfLanguageTag)
        .toList();
    final allRdfFields = [...constructorRdfFields, ...nonConstructorFields];

    if (!isMethodBased &&
        allRdfFields.any((p) => !(p.isRdfLanguageTag || p.isRdfValue))) {
      throw Exception(
        'LiteralMapper must only have Value or LanguagePart part parameters, but found: ${allRdfFields.where((p) => !(p.isRdfLanguageTag || p.isRdfValue)).map((p) => p.name)}',
      );
    }

    // Find the RDF value and language tag fields from all fields (constructor + non-constructor)
    final rdfValueParameter =
        allRdfFields.where((p) => p.isRdfValue).singleOrNull;
    final rdfLanguageTagParameter =
        allRdfFields.where((p) => p.isRdfLanguageTag).singleOrNull;

    final properties =
        _buildPropertyData(className, resourceInfo.fields, mapperImportUri);

    return [
      LiteralMapperTemplateData(
          className: className,
          mapperClassName: mapperClassName,
          mapperInterfaceName: mapperInterfaceName,
          datatype: datatype,
          fromLiteralTermMethod: fromLiteralTermMethod,
          toLiteralTermMethod: toLiteralTermMethod,
          constructorParameters: constructorParameters,
          nonConstructorFields: nonConstructorFields,
          registerGlobally: resourceInfo.annotation.registerGlobally,
          properties: properties,
          rdfValue: rdfValueParameter,
          rdfLanguageTag: rdfLanguageTagParameter)
    ];
  }

  static List<MappableClassMapperTemplateData> buildIriMapper(
      ValidationContext context, IriInfo iriInfo, String mapperImportUri) {
    final annotation = iriInfo.annotation;
    if (annotation.mapper != null) {
      throw Exception(
        'IriMapper cannot have a mapper defined in the annotation.',
      );
    }
    if (annotation.templateInfo == null) {
      throw Exception(
        'IriMapper must have a template defined in the annotation.',
      );
    }
    return _buildIriMapper(
        className: iriInfo.className,
        templateInfo: annotation.templateInfo!,
        iriParts: annotation.iriParts,
        mapperClassName: Code.type(
            '${iriInfo.className.codeWithoutAlias}Mapper',
            importUri: mapperImportUri),
        constructors: iriInfo.constructors,
        fields: iriInfo.fields,
        registerGlobally: annotation.registerGlobally,
        mapperImportUri: mapperImportUri);
  }

  static List<MappableClassMapperTemplateData> _buildIriMapper(
      {required Code className,
      required final IriTemplateInfo templateInfo,
      final List<IriPartInfo>? iriParts,
      required Code mapperClassName,
      List<ConstructorInfo> constructors = const [],
      List<FieldInfo> fields = const [],
      bool registerGlobally = false,
      required String mapperImportUri}) {
    final mapperInterfaceName =
        Code.type('IriTermMapper', importUri: importRdfMapper);

    // Build IRI strategy data
    final iriData = _buildIriData(
        templateInfo.template,
        null,
        _buildMapperInterfaceType(mapperInterfaceName, className),
        iriParts,
        templateInfo,
        fields)!;
    if (iriData.template == null) {
      throw Exception(
        'Trying to generate an IRI mapper for resource ${className}, but IRI template is not defined. This should not be possible.',
      );
    }
    // Build context providers for context variables
    final contextProviders = _buildContextProvidersForIriTemplate(templateInfo);

    // Build constructor parameters
    final constructorParameters = _buildConstructorParameters(
        className, constructors, fields, mapperImportUri);

    // Build non-constructor fields that are IRI parts
    final nonConstructorFields = _buildNonConstructorFields(
            className, constructorParameters, fields, iriData, mapperImportUri)
        .where((p) => p.isIriPart)
        .toList();

    // Check that all constructor parameters and non-constructor fields are IRI parts
    final allConstructorParams =
        constructorParameters.where((p) => !p.isIriPart);
    if (allConstructorParams.isNotEmpty) {
      throw Exception(
        'IriMapper constructor must only have IRI part parameters, but found: ${allConstructorParams.map((p) => p.name).join(', ')}',
      );
    }

    final properties = _buildPropertyData(className, fields, mapperImportUri);
    final singleMappedValue = templateInfo.propertyVariables
        .where((v) => v.isMappedValue)
        .map((v) => VariableNameData(
            isMappedValue: v.isMappedValue,
            variableName: v.name,
            isString: className == _stringType,
            placeholder: '{${v.name}}'))
        .singleOrNull;
    return [
      IriMapperTemplateData(
          className: className,
          mapperClassName: mapperClassName,
          mapperInterfaceName: mapperInterfaceName,
          iriStrategy: iriData,
          contextProviders: contextProviders,
          constructorParameters: constructorParameters,
          nonConstructorFields: nonConstructorFields,
          needsReader: fields.any((p) => p.propertyInfo != null),
          registerGlobally: registerGlobally,
          properties: properties,
          singleMappedValue: singleMappedValue),
    ];
  }

  static List<PropertyData> _buildPropertyData(
      Code className, List<FieldInfo> fields, String mapperImportUri) {
    final provides = collectProvidesByVariableNames(fields);
    return fields.where((p) => p.propertyInfo != null).map((p) {
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, p.name, p.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);
      return PropertyData(
        isRdfProperty: p.propertyInfo != null,
        isRequired: p.isRequired,
        isFieldNullable: !p.isRequired,
        include: p.propertyInfo!.annotation.include,
        predicate: p.propertyInfo!.annotation.predicate.code,
        propertyName: p.propertyInfo!.name,
        defaultValue: toCode(p.propertyInfo!.annotation.defaultValue),
        hasDefaultValue: p.propertyInfo!.annotation.defaultValue != null,
        includeDefaultsInSerialization:
            p.propertyInfo!.annotation.includeDefaultsInSerialization,
        mapperFieldName: mapperFieldName,
        mapperParameterSerializer: mapperParameterSerializer,
        mapperParameterDeserializer: mapperParameterDeserializer,
        mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameCode,
        mapperDeserializerCode: mapperDeserializerCode ?? mapperFieldNameCode,
      );
    }).toList();
  }

  /// Builds the type IRI expression.
  static Code? _buildTypeIri(ResourceInfo resourceInfo) {
    final classIriInfo = resourceInfo.annotation.classIri;
    return classIriInfo?.code;
  }

  static IriData? _buildIriStrategyForResource(ResourceInfo resourceInfo) {
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
        resourceInfo.fields);
  }

  /// Builds IRI strategy data.
  static IriData? _buildIriData(
      String? template,
      MapperRefInfo<IriTermMapper>? mapper,
      Code? type,
      List<IriPartInfo>? iriParts,
      IriTemplateInfo? templateInfo,
      List<FieldInfo>? fields) {
    MapperRefData? mapperRef;
    if (mapper != null && type != null) {
      if (mapper.name != null) {
        mapperRef = MapperRefData(
          name: mapper.name,
          isNamed: true,
          type: type,
        );
      } else if (mapper.type != null) {
        final typeValue = mapper.type?.toTypeValue();
        if (typeValue != null) {
          mapperRef = MapperRefData(
            implementationType: typeToCode(typeValue),
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
          instanceInitializationCode: toCode(mapper.instance),
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
          iriParts?.length == 1 && template == '{+${iriParts![0].name}}',
      mapper: mapperRef,
      hasMapper: mapperRef != null,
      iriMapperParts: iriMapperParts,
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

  static final _stringType = Code.coreType('String');

  static IriTemplateData _buildTemplateData(
      IriTemplateInfo iriTemplateInfo, List<FieldInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: _stringType == field.type,
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
      interpolatedTemplate: _buildInterpolatedTemplate(iriTemplateInfo),
    );
  }

  static String _buildInterpolatedTemplate(IriTemplateInfo iriTemplateInfo) {
    String interpolatedTemplate = iriTemplateInfo.template;

    // Replace variables with Dart string interpolation syntax
    for (final variable in iriTemplateInfo.variableNames) {
      final placeholder =
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}';
      interpolatedTemplate = interpolatedTemplate.replaceAll(
          placeholder, '\${${variable.dartPropertyName}}');
    }

    return interpolatedTemplate;
  }

  static List<ContextProviderData> _buildContextProvidersForResource(
      ResourceInfo resourceInfo) {
    final provides = collectProvidesVariableNames(resourceInfo.fields);
    final annotation = resourceInfo.annotation;
    return [
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
              variable, f.type == _stringType /* is string */);
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
  }

  static Set<String> collectProvidesVariableNames(List<FieldInfo> fields) =>
      fields.map((f) => f.provides?.name).nonNulls.toSet();

  static Map<String, ProvidesInfo> collectProvidesByVariableNames(
          List<FieldInfo> fields) =>
      {
        for (final p in fields
            .expand((f) => f.provides == null ? const [] : [f.provides!]))
          p.name: p
      };

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

  /// Builds constructor parameter data for the template.
  static Iterable<ParameterData> _buildNonConstructorFields(
      Code className,
      List<ParameterData> constructorParameters,
      List<FieldInfo> fields,
      IriData? iriStrategy,
      String mapperImportUri) {
    final constructorParameterNames =
        constructorParameters.map((p) => p.name).toSet();
    final iriPartNameByPropertyName = {
      for (var pv in (iriStrategy?.iriMapperParts ?? <IriPartData>[]))
        pv.dartPropertyName: pv.name
    };
    final provides = collectProvidesByVariableNames(fields);
    return fields
        .where((f) => !constructorParameterNames.contains(f.name))
        .map((field) {
      final predicateCode = field.propertyInfo?.annotation.predicate.code;
      final defaultValue = field.propertyInfo?.annotation.defaultValue;
      final iriPartName = iriPartNameByPropertyName[field.name];
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, field.name, field.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameAsCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);
      return ParameterData(
        name: field.name,
        dartType: field.type,
        isRequired: field.isRequired,
        isFieldNullable: !field.isRequired,
        isIriPart: iriPartName != null,
        isRdfProperty: predicateCode != null,
        isNamed: false,
        iriPartName: iriPartName,
        predicate: predicateCode,
        defaultValue: toCode(defaultValue),
        hasDefaultValue: defaultValue != null,
        isRdfLanguageTag: field.isRdfLanguageTag,
        isRdfValue: field.isRdfValue,
        mapperFieldName: mapperFieldName,
        mapperParameterSerializer: mapperParameterSerializer,
        mapperParameterDeserializer: mapperParameterDeserializer,
        mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameAsCode,
        mapperDeserializerCode: mapperDeserializerCode ?? mapperFieldNameAsCode,
      );
    });
  }

  static List<ParameterData> _buildConstructorParameters(
      Code className,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields,
      String mapperImportUri) {
    final provides = collectProvidesByVariableNames(fields);
    final parameters = <ParameterData>[];
    if (constructors.isEmpty) {
      return parameters; // No constructors, return empty list
    }
    // Find the default constructor or use the first one if no default exists
    final defaultConstructor = constructors.firstWhere(
      (c) => c.isDefaultConstructor,
      orElse: () => constructors.first,
    );

    // Process each parameter in the constructor
    for (final param in defaultConstructor.parameters) {
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, param.name, param.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameAsCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);
      parameters.add(
        ParameterData(
          name: param.name,
          dartType: param.type,
          isRequired: param.isRequired,
          // For RDF properties, check if the field is nullable. If not an RDF property, assume non-nullable
          isFieldNullable: param.propertyInfo != null
              ? !param.propertyInfo!.isRequired
              : false,
          isIriPart: param.isIriPart,
          isRdfProperty: param.propertyInfo != null,
          isNamed: param.isNamed,
          iriPartName: param.iriPartName,
          predicate: param.propertyInfo?.annotation.predicate.code,
          defaultValue: toCode(param.propertyInfo?.annotation.defaultValue),
          hasDefaultValue: param.propertyInfo?.annotation.defaultValue != null,
          isRdfLanguageTag: param.isRdfLanguageTag,
          isRdfValue: param.isRdfValue,
          mapperFieldName: mapperFieldName,
          mapperParameterSerializer: mapperParameterSerializer,
          mapperParameterDeserializer: mapperParameterDeserializer,
          mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameAsCode,
          mapperDeserializerCode:
              mapperDeserializerCode ?? mapperFieldNameAsCode,
        ),
      );
    }

    return parameters;
  }

  static const (
    String? mapperFieldName,
    Code? mapperSerializerCode,
    Code? mapperDeserializerCode,
    String? mapperParameterSerializer,
    String? mapperParameterDeserializer
  ) noMapperInfos = (
    null,
    null,
    null,
    null,
    null,
  );

  static (
    String? mapperFieldName,
    Code? mapperSerializerCode,
    Code? mapperDeserializerCode,
    String? mapperParameterSerializer,
    String? mapperParameterDeserializer
  ) _extractPropertyMapperInfos(
      Code className,
      String fieldName,
      PropertyInfo? propertyInfo,
      Map<String, ProvidesInfo> providesByVariableNames,
      String mapperImportUri) {
    final iri = propertyInfo?.annotation.iri;
    if (iri != null) {
      final template = iri.template;
      final iriMapperFieldName = _buildMapperFieldName(fieldName);
      final generatedMapperName =
          buildPropertyMapperName(className, fieldName, mapperImportUri);
      return (
        iriMapperFieldName,
        template == null
            ? null
            : buildIriMapperSerializerCode(generatedMapperName, template,
                iriMapperFieldName, providesByVariableNames),
        template == null
            ? null
            : buildIriMapperDeserializerCode(generatedMapperName, template,
                iriMapperFieldName, providesByVariableNames),
        'iriTermSerializer',
        'iriTermDeserializer'
      );
    }
    final literal = propertyInfo?.annotation.literal;
    if (literal != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'literalTermSerializer',
        'literalTermDeserializer'
      );
    }
    final globalResource = propertyInfo?.annotation.globalResource;
    if (globalResource != null && globalResource.mapper != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'resourceSerializer',
        'globalResourceDeserializer'
      );
    }
    final localResource = propertyInfo?.annotation.localResource;
    if (localResource != null && localResource.mapper != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'resourceSerializer',
        'localResourceDeserializer'
      );
    }
    return noMapperInfos;
  }

  static buildIriMapperDeserializerCode(
      Code generatedMapperConstructorName,
      IriTemplateInfo iri,
      String iriMapperFieldName,
      Map<String, ProvidesInfo> providesByVariableNames) {
    if (iri.contextVariables.isEmpty) {
      // No context variables at all, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    final hasProvides =
        iri.contextVariables.any((v) => providesByVariableNames.containsKey(v));
    if (!hasProvides) {
      // All context variables will be injected, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    // we will need to build our own initialization code
    return Code.combine([
      generatedMapperConstructorName,
      Code.literal('('),
      ...iri.contextVariables.map((v) {
        final provides = providesByVariableNames[v];
        if (provides == null) {
          // context variable is not provided, so it will be injected as a field
          return Code.literal('${v}Provider: _${v}Provider, ');
        }
        return Code.literal(
            "${v}Provider: () => throw Exception('Must not call provider for deserialization'), ");
      }),
      Code.literal(')')
    ]);
  }

  static buildIriMapperSerializerCode(
      Code generatedMapperConstructorName,
      IriTemplateInfo iri,
      String iriMapperFieldName,
      Map<String, ProvidesInfo> providesByVariableNames) {
    if (iri.contextVariables.isEmpty) {
      // No context variables at all, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    final hasProvides =
        iri.contextVariables.any((v) => providesByVariableNames.containsKey(v));
    if (!hasProvides) {
      // All context variables will be injected, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    // we will need to build our own initialization code
    return Code.combine([
      generatedMapperConstructorName,
      Code.literal('('),
      ...iri.contextVariables.map((v) {
        final provides = providesByVariableNames[v];
        if (provides == null) {
          // context variable is not provided, so it will be injected as a field
          return Code.literal('${v}Provider: _${v}Provider, ');
        }
        return Code.literal(
            '${v}Provider: () => resource.${provides.dartPropertyName}, ');
      }),
      Code.literal(')')
    ]);
  }
}
