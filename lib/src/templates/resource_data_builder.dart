import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/custom_mapper_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';

final _log = Logger('GlobalResourceDataBuilder');

/// Builds template data from processed resource information.
class ResourceDataBuilder {
  /// Builds template data for a global resource mapper.
  static ResourceMapperTemplateData buildResourceMapper(
      ResourceInfo resourceInfo, String mapperImportUri) {
    assert(resourceInfo.annotation.mapper == null);
    final isGlobalResource = resourceInfo.annotation is RdfGlobalResourceInfo;
    final className = resourceInfo.className;
    final mapperClassName = Code.type('${className.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final mapperInterfaceName =
        CustomMapperDataBuilder.mapperInterfaceNameFor(resourceInfo.annotation);
    final termClass =
        isGlobalResource ? Code.type('IriTerm') : Code.type('BlankNodeTerm');
    // Build imports
    final imports = _buildImports(resourceInfo, className.imports);

    // Build type IRI expression
    final typeIri = _buildTypeIri(resourceInfo);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategy(resourceInfo);

    // Build context providers for context variables
    final contextProviders = _buildContextProviders(resourceInfo);

    // Build constructor parameters
    final resourceConstructorParameters =
        _buildResourceConstructorParameters(resourceInfo);

    final properties = resourceInfo.fields
        .where((p) => p.propertyInfo != null)
        .map((p) => PropertyData(
            isRdfProperty: p.propertyInfo != null,
            isRequired: p.isRequired,
            predicate: p.propertyInfo!.annotation.predicate.code,
            propertyName: p.propertyInfo!.name))
        .toList();

    return ResourceMapperTemplateData(
        imports: imports,
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

  /// Builds the list of required imports.
  static List<ImportData> _buildImports(
      ResourceInfo resourceInfo, Set<String> knownImports) {
    final imports = <String>{
      'package:rdf_core/rdf_core.dart',
      'package:rdf_mapper/rdf_mapper.dart',
      ...knownImports
    };

    return imports.map(ImportData.new).toList();
  }

  /// Builds the type IRI expression.
  static Code? _buildTypeIri(ResourceInfo resourceInfo) {
    final classIriInfo = resourceInfo.annotation.classIri;
    return classIriInfo?.code;
  }

  /// Builds IRI strategy data.
  static IriStrategyData? _buildIriStrategy(ResourceInfo resourceInfo) {
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

    final template = iriStrategy.template;
    final mapper = iriStrategy.mapper;
    final type = iriStrategy.iriMapperType;
    MapperRefData? mapperRef;
    if (mapper != null && type != null) {
      if (mapper.name != null) {
        mapperRef = MapperRefData(
          name: mapper.name,
          isNamed: true,
          type: type.type,
        );
      } else if (mapper.type != null) {
        final typeValue = mapper.type?.toTypeValue();
        if (typeValue != null) {
          mapperRef = MapperRefData(
            implementationType: typeToCode(typeValue),
            isTypeBased: true,
            type: type.type,
          );
        } else {
          _log.warning('Mapper type is not based on a type: $mapper');
        }
      } else if (mapper.instance != null) {
        mapperRef = MapperRefData(
          isInstance: true,
          type: type.type,
          instanceInitializationCode: toCode(mapper.instance),
        );
      }
    }
    final iriMapperParts = type?.parts
            .map((p) => IriPartData(
                  name: p.name,
                  dartPropertyName: p.dartPropertyName,
                ))
            .toList() ??
        [];
    return IriStrategyData(
      template: template == null
          ? null
          : _buildTemplateData(iriStrategy.templateInfo!),
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

  static List<ContextProviderData> _buildContextProviders(
      ResourceInfo resourceInfo) {
    final annotation = resourceInfo.annotation;
    return [
      if (annotation is RdfGlobalResourceInfo)
        ..._buildContextProvidersForIriStrategy(annotation.iri?.templateInfo)
    ];
  }

  /// Builds context provider data for context variables.
  static List<ContextProviderData> _buildContextProvidersForIriStrategy(
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
  static List<ParameterData> _buildResourceConstructorParameters(
      ResourceInfo resourceInfo) {
    final parameters = <ParameterData>[];

    // Find the default constructor or use the first one if no default exists
    final defaultConstructor = resourceInfo.constructors.firstWhere(
      (c) => c.isDefaultConstructor,
      orElse: () => resourceInfo.constructors.first,
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
