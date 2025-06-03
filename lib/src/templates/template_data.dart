sealed class MappableClassMapperTemplateData {
  /// Required imports for the generated file
  List<ImportData> get imports;

  /// The name of the Dart class being mapped
  String get className;

  /// The name of the generated mapper class
  String get mapperClassName;

  Map<String, dynamic> toMap();
}

/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class GlobalResourceMapperTemplateData
    implements MappableClassMapperTemplateData {
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

/// Template data for the entire generated file.
///
/// This contains the file header, all imports, and all mapper classes.
class FileTemplateData {
  /// Header information with source path and generation timestamp
  final FileHeaderData header;

  /// All imports required for the file
  final List<ImportData> imports;

  /// All generated mapper classes
  final List<MapperData> mappers;

  const FileTemplateData({
    required this.header,
    required this.imports,
    required this.mappers,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'header': header.toMap(),
      'imports': imports.map((i) => i.toMap()).toList(),
      'mappers': mappers.map((m) => m.toMap()).toList(),
    };
  }
}

/// Template data for file header information.
class FileHeaderData {
  final String sourcePath;
  final String generatedOn;

  const FileHeaderData({
    required this.sourcePath,
    required this.generatedOn,
  });

  Map<String, dynamic> toMap() => {
        'sourcePath': sourcePath,
        'generatedOn': generatedOn,
      };
}

/// Template data for a single mapper class.
class MapperData {
  final MappableClassMapperTemplateData mapperData;

  const MapperData(this.mapperData);

  Map<String, dynamic> toMap() => mapperData.toMap();
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
  // FIXME: what is this?
  final String? baseIri;
  // FIXME: what is this?
  final String? placeholder;

  const IriStrategyData({
    required this.hasTemplate,
    this.template,
    this.baseIri,
    this.placeholder,
  });

  Map<String, dynamic> toMap() => {
        'hasTemplate': hasTemplate,
        'template': template,
        'baseIri': baseIri,
        'placeholder': placeholder,
      };
}

/// Data for IRI parts parsing
class IriPartsData {
  final bool hasTemplate;
  // FIXME: slighty confusing - why is the template here and optional
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
  // FIXME: again - what is this
  final String placeholder;
  final String propertyName;
  // FIXME: again - what is this
  final String regexPattern;
  // FIXME: again - what is this
  final bool hasConverter;
  // FIXME: again - what is this
  final String? converter;

  const IriPartData({
    required this.placeholder,
    required this.propertyName,
    required this.regexPattern,
    required this.hasConverter,
    this.converter,
  });

  Map<String, dynamic> toMap() {
    return {
      'placeholder': placeholder,
      'propertyName': propertyName,
      'regexPattern': regexPattern,
      'hasConverter': hasConverter,
      'converter': converter,
    };
  }
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
  // FIXME: what is this?
  final bool hasConverter;
  // FIXME: what is this?
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
  // FIXME: what is this?
  final bool hasConverter;
  // FIXME: what is this?
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
