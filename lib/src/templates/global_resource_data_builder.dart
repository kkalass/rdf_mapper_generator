import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:logging/logging.dart';

final _log = Logger('GlobalResourceDataBuilder');

/// Builds template data from processed resource information.
class GlobalResourceDataBuilder {
  static GlobalResourceMapperCustomTemplateData buildGlobalResourceMapperCustom(
    GlobalResourceInfo resourceInfo,
  ) {
    assert(resourceInfo.annotation.mapper != null);

    // Build imports

    return GlobalResourceMapperCustomTemplateData(
      imports: const [],
    );
  }

  /// Builds template data for a global resource mapper.
  static GlobalResourceMapperTemplateData buildGlobalResourceMapper(
    GlobalResourceInfo resourceInfo,
  ) {
    assert(resourceInfo.annotation.mapper == null);
    final className = resourceInfo.className;
    final mapperClassName = '${className}Mapper';

    // Build imports
    final imports = _buildImports(resourceInfo);

    // Build type IRI expression
    final typeIri = _buildTypeIri(resourceInfo);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategy(resourceInfo);

    // Build context providers for context variables
    final contextProviders =
        _buildContextProviders(resourceInfo.annotation.iri?.templateInfo);

    // Build constructor parameters
    final resourceConstructorParameters =
        _buildResourceConstructorParameters(resourceInfo);

    return GlobalResourceMapperTemplateData(
      imports: imports,
      className: className,
      mapperClassName: mapperClassName,
      typeIri: typeIri,
      iriStrategy: iriStrategy,
      contextProviders: contextProviders,
      constructorParameters: resourceConstructorParameters,
      needsReader: resourceInfo.fields.any((p) => p.propertyInfo != null),
      registerGlobally: resourceInfo.annotation.registerGlobally,
    );
  }

  /// Builds the list of required imports.
  static List<ImportData> _buildImports(GlobalResourceInfo resourceInfo) {
    final imports = <String>{
      'package:rdf_core/rdf_core.dart',
      'package:rdf_mapper/rdf_mapper.dart',
    };

    // Add imports based on type IRI
    final classIriTermInfo = resourceInfo.annotation.classIri;
    if (classIriTermInfo?.importUri != null) {
      imports.add(classIriTermInfo!.importUri!);
    }

    // Add imports for property predicates from @RdfProperty fields
    for (final field in resourceInfo.fields) {
      if (field.propertyInfo?.annotation.predicate.importUri != null) {
        imports.add(field.propertyInfo!.annotation.predicate.importUri!);
      }
    }

    return imports.map(ImportData.new).toList();
  }

  /// Builds the type IRI expression.
  static String? _buildTypeIri(GlobalResourceInfo resourceInfo) {
    final classIriInfo = resourceInfo.annotation.classIri;
    return classIriInfo?.code;
  }

  /// Builds IRI strategy data.
  static IriStrategyData _buildIriStrategy(GlobalResourceInfo resourceInfo) {
    final iriStrategy = resourceInfo.annotation.iri;
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

  /// Builds context provider data for context variables.
  static List<ContextProviderData> _buildContextProviders(
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
      GlobalResourceInfo resourceInfo) {
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
