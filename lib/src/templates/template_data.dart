/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class GlobalResourceMapperTemplateData {
  /// Required imports for the generated file
  final List<ImportData> imports;

  /// The name of the Dart class being mapped
  final String className;

  /// The name of the generated mapper class
  final String mapperClassName;

  /// The type IRI expression (e.g., 'SchemaBook.classIri')
  final String typeIri;

  /// IRI strategy information
  final IriStrategyData? iriStrategy;

  /// IRI parts information for template-based IRIs
  final IriPartsData? iriParts;

  /// Constructor parameters information
  final List<ParameterData> constructorParameters;

  /// Property mapping information
  final List<PropertyData> properties;

  const GlobalResourceMapperTemplateData({
    required this.imports,
    required this.className,
    required this.mapperClassName,
    required this.typeIri,
    this.iriStrategy,
    this.iriParts,
    required this.constructorParameters,
    required this.properties,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'imports': imports.map((i) => i.toMap()).toList(),
      'className': className,
      'mapperClassName': mapperClassName,
      'typeIri': typeIri,
      'iriStrategy': iriStrategy?.toMap(),
      'iriParts': iriParts?.toMap(),
      'constructorParameters':
          constructorParameters.map((p) => p.toMap()).toList(),
      'properties': properties.map((p) => p.toMap()).toList(),
    };
  }
}

/// Data for import statements
class ImportData {
  final String import;

  const ImportData(this.import);

  Map<String, dynamic> toMap() => {'import': import};
}

/// Data for IRI strategy
class IriStrategyData {
  final bool hasTemplate;
  final String? template;
  final String? baseIri;

  const IriStrategyData({
    required this.hasTemplate,
    this.template,
    this.baseIri,
  });

  Map<String, dynamic> toMap() => {
        'hasTemplate': hasTemplate,
        'template': template,
        'baseIri': baseIri,
      };
}

/// Data for IRI parts parsing
class IriPartsData {
  final bool hasTemplate;
  final String? template;
  final List<IriPartData> iriParts;

  const IriPartsData({
    required this.hasTemplate,
    this.template,
    required this.iriParts,
  });

  Map<String, dynamic> toMap() => {
        'hasTemplate': hasTemplate,
        'template': template,
        'iriParts': iriParts.map((p) => p.toMap()).toList(),
      };
}

/// Data for individual IRI parts
class IriPartData {
  final String placeholder;
  final String propertyName;
  final String regexPattern;
  final bool hasConverter;
  final String? converter;

  const IriPartData({
    required this.placeholder,
    required this.propertyName,
    required this.regexPattern,
    required this.hasConverter,
    this.converter,
  });

  Map<String, dynamic> toMap() => {
        'placeholder': placeholder,
        'propertyName': propertyName,
        'regexPattern': regexPattern,
        'hasConverter': hasConverter,
        'converter': converter,
      };
}

/// Data for constructor parameters
class ParameterData {
  final String name;
  final String dartType;
  final bool isRequired;
  final bool isIriPart;
  final bool isRdfProperty;
  final String? iriPartName;
  final String? predicate;
  final String? defaultValue;
  final bool hasConverter;
  final String? converter;

  const ParameterData({
    required this.name,
    required this.dartType,
    required this.isRequired,
    required this.isIriPart,
    required this.isRdfProperty,
    this.iriPartName,
    this.predicate,
    this.defaultValue,
    required this.hasConverter,
    this.converter,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartType': dartType,
        'isRequired': isRequired,
        'isIriPart': isIriPart,
        'isRdfProperty': isRdfProperty,
        'iriPartName': iriPartName,
        'predicate': predicate,
        'defaultValue': defaultValue,
        'hasConverter': hasConverter,
        'converter': converter,
      };
}

/// Data for RDF properties
class PropertyData {
  final String propertyName;
  final String dartType;
  final bool isRequired;
  final bool isRdfProperty;
  final String? predicate;
  final bool hasConverter;
  final String? converter;

  const PropertyData({
    required this.propertyName,
    required this.dartType,
    required this.isRequired,
    required this.isRdfProperty,
    this.predicate,
    required this.hasConverter,
    this.converter,
  });

  Map<String, dynamic> toMap() => {
        'propertyName': propertyName,
        'dartType': dartType,
        'isRequired': isRequired,
        'isRdfProperty': isRdfProperty,
        'predicate': predicate,
        'hasConverter': hasConverter,
        'converter': converter,
      };
}
