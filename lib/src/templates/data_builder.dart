import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('GlobalResourceDataBuilder');

/// Builds template data from processed resource information.
class DataBuilder {
  static CustomMapperTemplateData buildCustomMapper(ValidationContext context,
      Code className, BaseMappingAnnotationInfo annotation) {
    assert(annotation.mapper != null);
    final mapper = annotation.mapper!;
    final mapperInterfaceName = _mapperInterfaceNameFor(annotation);

    final mapperInterfaceType = Code.combine([
      mapperInterfaceName,
      Code.literal('<'),
      className,
      Code.literal('>'),
    ]);
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
    return CustomMapperTemplateData(
      className: className,
      mapperInterfaceType: mapperInterfaceType,
      customMapperName: customMapperName,
      customMapperType: customMapperType,
      customMapperInstance: customMapperInstance,
      registerGlobally: annotation.registerGlobally,
    );
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
  static ResourceMapperTemplateData buildResourceMapper(
      ResourceInfo resourceInfo, String mapperImportUri) {
    assert(resourceInfo.annotation.mapper == null);
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
    final resourceConstructorParameters =
        _buildConstructorParameters(resourceInfo.constructors);

    final properties = _buildPropertyData(resourceInfo.fields);

    return ResourceMapperTemplateData(
        className: className,
        mapperClassName: mapperClassName,
        mapperInterfaceName: mapperInterfaceName,
        termClass: termClass,
        typeIri: typeIri,
        iriStrategy: iriStrategy,
        contextProviders: contextProviders,
        constructorParameters: resourceConstructorParameters,
        needsReader: resourceInfo.fields.any((p) => p.propertyInfo != null),
        registerGlobally: resourceInfo.annotation.registerGlobally,
        properties: properties);
  }

  static IriMapperTemplateData buildIriMapper(
      IriInfo resourceInfo, String mapperImportUri) {
    final annotation = resourceInfo.annotation;
    assert(annotation.mapper == null);
    final className = resourceInfo.className;
    final mapperClassName = Code.type('${className.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final mapperInterfaceName = _mapperInterfaceNameFor(annotation);

    // Build IRI strategy data
    final iriData = _buildIriData(
      annotation.template,
      annotation.mapper,
      Code.combine([
        mapperInterfaceName,
        Code.literal('<'),
        className,
        Code.literal('>')
      ]),
      annotation.iriParts,
      annotation.templateInfo,
    )!;
    if (iriData.template == null) {
      throw Exception(
        'Trying to generate an IRI mapper for resource ${resourceInfo.className}, but IRI template is not defined. This should not be possible.',
      );
    }
    // Build context providers for context variables
    final contextProviders =
        _buildContextProvidersForIriTemplate(annotation.templateInfo);

    // Build constructor parameters
    final constructorParameters =
        _buildConstructorParameters(resourceInfo.constructors);
    if (constructorParameters.any((p) => !p.isIriPart)) {
      throw Exception(
        'IriMapper must only have IRI part parameters, but found: ${constructorParameters.where((p) => !p.isIriPart).map((p) => p.name)}',
      );
    }
    final properties = _buildPropertyData(resourceInfo.fields);

    return IriMapperTemplateData(
        className: className,
        mapperClassName: mapperClassName,
        mapperInterfaceName: mapperInterfaceName,
        iriStrategy: iriData,
        contextProviders: contextProviders,
        constructorParameters: constructorParameters,
        needsReader: resourceInfo.fields.any((p) => p.propertyInfo != null),
        registerGlobally: resourceInfo.annotation.registerGlobally,
        properties: properties);
  }

  static List<PropertyData> _buildPropertyData(List<FieldInfo> fields) {
    return fields
        .where((p) => p.propertyInfo != null)
        .map((p) => PropertyData(
            isRdfProperty: p.propertyInfo != null,
            isRequired: p.isRequired,
            predicate: p.propertyInfo!.annotation.predicate.code,
            propertyName: p.propertyInfo!.name))
        .toList();
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
        iriStrategy.templateInfo);
  }

  /// Builds IRI strategy data.
  static IriData? _buildIriData(
      String? template,
      MapperRefInfo<IriTermMapper>? mapper,
      Code? type,
      List<IriPartInfo>? iriParts,
      IriTemplateInfo? templateInfo) {
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
    final iriMapperParts = iriParts
            ?.map((p) => IriPartData(
                  name: p.name,
                  dartPropertyName: p.dartPropertyName,
                ))
            .toList() ??
        [];
    return IriData(
      template: template == null ? null : _buildTemplateData(templateInfo!),
      mapper: mapperRef,
      hasMapper: mapperRef != null,
      iriMapperParts: iriMapperParts,
    );
  }

  static VariableNameData _buildVariableNameData(VariableName variable) {
    return VariableNameData(
      variableName: variable.dartPropertyName,
      placeholder:
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}',
    );
  }

  static IriTemplateData _buildTemplateData(IriTemplateInfo iriTemplateInfo) {
    return IriTemplateData(
      template: iriTemplateInfo.template,
      propertyVariables:
          iriTemplateInfo.propertyVariables.map(_buildVariableNameData).toSet(),
      contextVariables: iriTemplateInfo.contextVariableNames
          .map(_buildVariableNameData)
          .toSet(),
      variables:
          iriTemplateInfo.variableNames.map(_buildVariableNameData).toSet(),
      regexPattern:
          '^${buildRegexPattern(iriTemplateInfo.template, iriTemplateInfo.variableNames)}\\\$',
    );
  }

  static List<ContextProviderData> _buildContextProvidersForResource(
      ResourceInfo resourceInfo) {
    final annotation = resourceInfo.annotation;
    return [
      if (annotation is RdfGlobalResourceInfo)
        ..._buildContextProvidersForIriTemplate(annotation.iri?.templateInfo)
    ];
  }

  /// Builds context provider data for context variables.
  static List<ContextProviderData> _buildContextProvidersForIriTemplate(
      IriTemplateInfo? templateInfo) {
    if (templateInfo == null) return [];

    return templateInfo.contextVariableNames.map((variable) {
      final d = _buildVariableNameData(variable);
      return ContextProviderData(
        variableName: d.variableName,
        privateFieldName: '_${d.variableName}Provider',
        parameterName: '${d.variableName}Provider',
        placeholder: d.placeholder,
      );
    }).toList();
  }

  /// Builds constructor parameter data for the template.
  static List<ParameterData> _buildConstructorParameters(
      List<ConstructorInfo> constructors) {
    final parameters = <ParameterData>[];

    // Find the default constructor or use the first one if no default exists
    final defaultConstructor = constructors.firstWhere(
      (c) => c.isDefaultConstructor,
      orElse: () => constructors.first,
    );

    // Process each parameter in the constructor
    for (final param in defaultConstructor.parameters) {
      parameters.add(
        ParameterData(
          name: param.name,
          dartType: param.type,
          isRequired: param.isRequired,
          isIriPart: param.isIriPart,
          isRdfProperty: param.propertyInfo != null,
          isNamed: param.isNamed,
          iriPartName: param.iriPartName,
          predicate: param.propertyInfo?.annotation.predicate.code,
          defaultValue: toCode(param.propertyInfo?.annotation.defaultValue),
          hasDefaultValue: param.propertyInfo?.annotation.defaultValue != null,
        ),
      );
    }

    return parameters;
  }
}
