import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';

/// Builds template data from processed resource information.
class GlobalResourceDataBuilder {
  /// Builds template data for a global resource mapper.
  static GlobalResourceMapperTemplateData buildGlobalResourceMapper(
    GlobalResourceInfo resourceInfo,
  ) {
    final className = resourceInfo.className;
    final mapperClassName = '${className}Mapper';

    // Build imports
    final imports = _buildImports(resourceInfo);

    // Build type IRI expression
    final typeIri = _buildTypeIri(resourceInfo);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategy(resourceInfo);

    // Build IRI parts data
    final iriParts = _buildIriParts(resourceInfo);

    // Build constructor parameters
    final constructorParameters = _buildConstructorParameters(resourceInfo);

    // Build properties
    final properties = _buildProperties(resourceInfo);

    return GlobalResourceMapperTemplateData(
      imports: imports,
      className: className,
      mapperClassName: mapperClassName,
      typeIri: typeIri,
      iriStrategy: iriStrategy,
      iriParts: iriParts,
      constructorParameters: constructorParameters,
      properties: properties,
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
  static String _buildTypeIri(GlobalResourceInfo resourceInfo) {
    final classIriInfo = resourceInfo.annotation.classIri;
    return classIriInfo?.code ?? 'IriTerm("${classIriInfo?.value}")';
  }

  /// Builds IRI strategy data.
  static IriStrategyData? _buildIriStrategy(GlobalResourceInfo resourceInfo) {
    final iriStrategy = resourceInfo.annotation.iri;
    if (iriStrategy == null) return null;

    final hasTemplate = iriStrategy.template != null;
    return IriStrategyData(
      hasTemplate: hasTemplate,
      template: iriStrategy.template,
      baseIri: hasTemplate ? null : iriStrategy.template,
    );
  }

  /// Builds IRI parts data for template-based IRIs.
  static IriPartsData _buildIriParts(GlobalResourceInfo resourceInfo) {
    final iriParts = <IriPartData>[];
    final iriStrategy = resourceInfo.annotation.iri;

    if (iriStrategy?.template == null) {
      return IriPartsData(
        hasTemplate: false,
        template: null,
        iriParts: [],
      );
    }

    final template = iriStrategy!.template!;

    // Get template info to find property variables
    final templateInfo = iriStrategy.templateInfo;
    if (templateInfo != null) {
      // Find fields that correspond to property variables
      for (final variableName in templateInfo.propertyVariables) {
        // Find the field with this variable name (either field name or @RdfIriPart name)
        final field = resourceInfo.fields.firstWhere(
          (f) => f.name == variableName,
          orElse: () =>
              throw Exception('No field found for IRI part: $variableName'),
        );

        final regexPattern =
            '([^/]+)'; // Simplified regex for template variable

        print('Creating IriPartData:');
        print('  - placeholder: $variableName');
        print('  - propertyName: ${field.name}');
        print('  - regexPattern: $regexPattern');

        iriParts.add(IriPartData(
          placeholder: variableName,
          propertyName: field.name,
          regexPattern: regexPattern,
          hasConverter: false, // TODO: Implement converter detection
          converter: null,
        ));
      }
    }

    final partsData = IriPartsData(
      hasTemplate: true,
      template: template,
      iriParts: iriParts,
    );

    print('Built IriPartsData:');
    print('  - hasTemplate: ${partsData.hasTemplate}');
    print('  - template: ${partsData.template}');
    print(
        '  - iriParts: ${partsData.iriParts.map((p) => '${p.placeholder} -> ${p.propertyName}').join(', ')}');

    return partsData;
  }

  /// Builds constructor parameter data.
  static List<ParameterData> _buildConstructorParameters(
    GlobalResourceInfo resourceInfo,
  ) {
    return resourceInfo.fields.map((field) {
      final propertyInfo = field.propertyInfo;
      final isIriPart = _isIriPartField(field, resourceInfo);
      final isRdfProperty = propertyInfo != null && !isIriPart;

      return ParameterData(
        name: field.name,
        dartType: field.type,
        isRequired: field.isRequired,
        isIriPart: isIriPart,
        isRdfProperty: isRdfProperty,
        iriPartName: isIriPart ? field.name : null,
        predicate: isRdfProperty ? _buildPredicate(field) : null,
        defaultValue: null, // TODO: Extract default value from constructor
        hasConverter: false, // TODO: Implement converter detection
        converter: null,
      );
    }).toList();
  }

  /// Builds property data for serialization.
  static List<PropertyData> _buildProperties(GlobalResourceInfo resourceInfo) {
    return resourceInfo.fields
        .where((field) =>
            field.propertyInfo != null && !_isIriPartField(field, resourceInfo))
        .map((field) {
      return PropertyData(
        propertyName: field.name,
        dartType: field.type,
        isRequired: field.isRequired,
        isRdfProperty: true,
        predicate: _buildPredicate(field),
        hasConverter: false, // TODO: Implement converter detection
        converter: null,
      );
    }).toList();
  }

  /// Checks if a field is used as an IRI part in the template.
  static bool _isIriPartField(
      FieldInfo field, GlobalResourceInfo resourceInfo) {
    final templateInfo = resourceInfo.annotation.iri?.templateInfo;
    if (templateInfo == null) return false;

    // Check if field name is in property variables
    return templateInfo.propertyVariables.contains(field.name);
  }

  /// Builds the predicate expression for a property.
  static String _buildPredicate(FieldInfo field) {
    final predicate = field.propertyInfo?.annotation.predicate;
    return predicate?.code ?? 'IriTerm("${predicate?.value}")';
  }
}
