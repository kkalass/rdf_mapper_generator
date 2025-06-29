import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/mappers/mapped_model_builder.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/mappers/util.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('IriModelBuilderSupport');

class IriModelBuilderSupport {
  /// FIXME bad code
  static IriModel? buildIriData(
      String? template,
      MapperRefInfo<IriTermMapper>? mapper,
      Code? type,
      List<IriPartInfo>? iriParts,
      IriTemplateInfo? templateInfo,
      List<FieldInfo>? fields,
      UnresolvedInstantiationCodeData unresolved) {
    MapperRefModel? mapperRef;
    if (mapper != null && type != null) {
      if (mapper.name != null) {
        mapperRef = MapperRefModel(
          name: mapper.name,
          isNamed: true,
          type: type,
        );
      } else if (mapper.type != null) {
        final typeValue = mapper.type;
        if (typeValue != null) {
          mapperRef = MapperRefModel(
            instanceInitializationCode:
                ResolvableInstantiationCodeData(typeValue.name, unresolved),
            isTypeBased: true,
            type: type,
          );
        } else {
          _log.warning('Mapper type is not based on a type: $mapper');
        }
      } else if (mapper.instance != null) {
        mapperRef = MapperRefModel(
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
            ?.map((p) => IriPartModel(
                  name: p.name,
                  dartPropertyName: p.dartPropertyName,
                  isRdfProperty:
                      rdfPropertyFields?.contains(p.dartPropertyName) ?? false,
                ))
            .toList() ??
        [];
    return IriModel(
      template: template == null
          ? null
          : _buildTemplateData(templateInfo!, fields ?? []),
      hasFullIriPartTemplate: hasFullIriPartTemplate(iriParts, template),
      mapper: mapperRef,
      hasMapper: mapperRef != null,
      iriMapperParts: iriMapperParts,
    );
  }

  static IriTemplateModel _buildTemplateData(
      IriTemplateInfo iriTemplateInfo, List<FieldInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: stringType == field.type,
    };
    VariableNameModel buildVariableNameData(VariableName variable) =>
        _buildVariableNameData(
            variable, isStringByFieldName[variable.dartPropertyName] ?? false);
    var propertyVariables =
        iriTemplateInfo.propertyVariables.map(buildVariableNameData).toSet();
    return IriTemplateModel(
      template: iriTemplateInfo.template,
      propertyVariables: propertyVariables,
      contextVariables: iriTemplateInfo.contextVariableNames
          .map(buildVariableNameData)
          .toSet(),
      variables:
          iriTemplateInfo.variableNames.map(buildVariableNameData).toSet(),
      regexPattern:
          '^${buildRegexPattern(iriTemplateInfo.template, iriTemplateInfo.variableNames)}\\\$',
      interpolatedTemplate: buildInterpolatedTemplate(iriTemplateInfo),
    );
  }

  static Set<VariableNameModel> buildPropertyVariables(
      IriTemplateInfo iriTemplateInfo, List<FieldInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: stringType == field.type,
    };
    VariableNameModel buildVariableNameData(VariableName variable) =>
        _buildVariableNameData(
            variable, isStringByFieldName[variable.dartPropertyName] ?? false);
    return iriTemplateInfo.propertyVariables.map(buildVariableNameData).toSet();
  }

  static VariableNameModel _buildVariableNameData(
      VariableName variable, bool isString) {
    return VariableNameModel(
      isString: isString,
      variableName: variable.dartPropertyName,
      isMappedValue: variable.isMappedValue,
      placeholder:
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}',
    );
  }

  static String buildInterpolatedTemplate(IriTemplateInfo iriTemplateInfo) {
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

  static bool hasFullIriPartTemplate(
          List<IriPartInfo>? iriParts, String? template) =>
      iriParts?.length == 1 && template == '{+${iriParts![0].name}}';

  static List<MapperModel> buildIriMapperFromIriInfo(
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
    return buildIriMapper(
        context: context,
        mappedClassName: iriInfo.className,
        templateInfo: annotation.templateInfo!,
        iriParts: annotation.iriParts,
        mapperClassName:
            _toImplementationClass(iriInfo.className, mapperImportUri),
        constructors: iriInfo.constructors,
        fields: iriInfo.fields,
        registerGlobally: annotation.registerGlobally,
        mapperImportUri: mapperImportUri,
        enumValues: iriInfo.enumValues);
  }

  static Code _toImplementationClass(Code mappedClass, String mapperImportUri) {
    return Code.type('${mappedClass.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
  }

  static List<MapperModel> buildIriMapper(
      {required ValidationContext context,
      required Code mappedClassName,
      required final IriTemplateInfo templateInfo,
      final List<IriPartInfo>? iriParts,
      required Code mapperClassName,
      List<ConstructorInfo> constructors = const [],
      List<FieldInfo> fields = const [],
      bool registerGlobally = false,
      required String mapperImportUri,
      List<EnumValueInfo> enumValues = const []}) {
    final singleMappedValue = templateInfo.propertyVariables
        .where((v) => v.isMappedValue)
        .map((v) => VariableNameModel(
            isMappedValue: v.isMappedValue,
            variableName: v.name,
            isString: mappedClassName == stringType,
            placeholder: '{${v.name}}'))
        .singleOrNull;

    final propertyVariables =
        IriModelBuilderSupport.buildPropertyVariables(templateInfo, fields);
    final regexPattern =
        '^${buildRegexPattern(templateInfo.template, templateInfo.variableNames)}\\\$';
    final interpolatedTemplate =
        IriModelBuilderSupport.buildInterpolatedTemplate(templateInfo);
    final contextVariables = templateInfo.contextVariableNames.map((variable) {
      final id = DependencyId.generateId();
      final dependency = GenericDependency(
          id: id,
          name: variable.name + 'Provider',
          type: Code.literal('String Function()'));
      final v = VariableForDependencyModel(
        name: variable,
        dependencyId: id,
      );
      return (v, dependency);
    }).toList();
    final dependencies = contextVariables.map((v) => v.$2).toList();
    if (enumValues.isNotEmpty) {
      return buildIriEnumMapper(
        templateInfo,
        mappedClassName,
        mapperImportUri,
        constructors,
        fields,
        context,
        mapperClassName,
        registerGlobally,
        dependencies,
        interpolatedTemplate,
        propertyVariables,
        regexPattern,
        contextVariables,
        singleMappedValue,
        enumValues,
      );
    }
    return buildIriClassMapper(
        mappedClassName,
        mapperImportUri,
        constructors,
        fields,
        context,
        mapperClassName,
        registerGlobally,
        dependencies,
        interpolatedTemplate,
        propertyVariables,
        regexPattern,
        contextVariables,
        singleMappedValue);
  }

  static List<MapperModel> buildIriEnumMapper(
      IriTemplateInfo templateInfo,
      Code mappedClassName,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields,
      ValidationContext context,
      Code mapperClassName,
      bool registerGlobally,
      List<GenericDependency> dependencies,
      String interpolatedTemplate,
      Set<VariableNameModel> propertyVariables,
      String regexPattern,
      List<(VariableForDependencyModel, GenericDependency)> contextVariables,
      VariableNameModel? singleMappedValue,
      List<EnumValueInfo> enumValues) {
    return [
      IriEnumMapperModel(
          id: MapperId.fromImplementationClass(mapperClassName),
          enumValues: enumValues.map(toEnumValueModel).toList(),
          mappedClass: mappedClassName,
          implementationClass: mapperClassName,
          registerGlobally: registerGlobally,
          dependencies: dependencies,
          interpolatedTemplate: interpolatedTemplate,
          propertyVariables: propertyVariables,
          regexPattern: regexPattern,
          contextVariables: contextVariables.map((v) => v.$1).toSet(),
          singleMappedValue: singleMappedValue,
          hasFullIriTemplate: IriModelBuilderSupport.hasFullIriPartTemplate(
              templateInfo.iriParts, templateInfo.template)),
    ];
  }

  static List<MapperModel> buildIriClassMapper(
      Code mappedClassName,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields,
      ValidationContext context,
      Code mapperClassName,
      bool registerGlobally,
      List<GenericDependency> dependencies,
      String interpolatedTemplate,
      Set<VariableNameModel> propertyVariables,
      String regexPattern,
      List<(VariableForDependencyModel, GenericDependency)> contextVariables,
      VariableNameModel? singleMappedValue) {
    final mappedClassModel = MappedClassModelBuilder.buildMappedClassModel(
        mappedClassName,
        mapperImportUri,
        constructors,
        fields,
        (field) => field.isIriPart);

    // Check that all constructor parameters and non-constructor fields are IRI parts
    final nonIriPartConstructorParams =
        mappedClassModel.constructorParameters.where((p) => !p.isIriPart);
    if (nonIriPartConstructorParams.isNotEmpty) {
      context.addError(
        'Iri class constructor must only have IRI part parameters, but found: ${nonIriPartConstructorParams.map((p) => p.name).join(', ')}',
      );
      return const [];
    }
    return [
      IriClassMapperModel(
          id: MapperId.fromImplementationClass(mapperClassName),
          mappedClass: mappedClassName,
          mappedClassModel: mappedClassModel,
          implementationClass: mapperClassName,
          registerGlobally: registerGlobally,
          dependencies: dependencies,
          interpolatedTemplate: interpolatedTemplate,
          propertyVariables: propertyVariables,
          regexPattern: regexPattern,
          contextVariables: contextVariables.map((v) => v.$1).toSet(),
          singleMappedValue: singleMappedValue),
    ];
  }
}
