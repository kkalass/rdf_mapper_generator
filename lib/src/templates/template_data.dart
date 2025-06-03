import 'package:rdf_mapper_generator/src/templates/util.dart';

sealed class MappableClassMapperTemplateData {
  /// Required imports for the generated file
  List<ImportData> get imports;

  Map<String, dynamic> toMap();
}

// FIXME: implement properly, this is for @RdfGlobalResource where
// a custom mapper is used via one of the constructors
class GlobalResourceMapperCustomTemplateData
    implements MappableClassMapperTemplateData {
  /// Required imports for the generated file
  final List<ImportData> imports;

  const GlobalResourceMapperCustomTemplateData({
    required this.imports,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'imports': imports.map((i) => i.toMap()).toList(),
    };
  }
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
  final String? typeIri;

  /// IRI strategy information
  final IriStrategyData iriStrategy;

  /// Constructor parameters information
  final List<ParameterData> constructorParameters = const [];

  /// Property mapping information
  final List<PropertyData> properties = const [];

  const GlobalResourceMapperTemplateData({
    required this.imports,
    required this.className,
    required this.mapperClassName,
    required this.typeIri,
    required this.iriStrategy,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'imports': imports.map((i) => i.toMap()).toList(),
      'className': className,
      'mapperClassName': mapperClassName,
      'typeIri': typeIri,
      'hasTypeIri': typeIri != null,
      'iriStrategy': iriStrategy.toMap(),
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

class IriTemplateData {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<String> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<String> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<String> contextVariables;

  const IriTemplateData({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
  });

  Map<String, dynamic> toMap() {
    return {
      'template': template,
      'variables': toMustacheList(variables.toList()),
      'propertyVariables': toMustacheList(propertyVariables.toList()),
      'contextVariables': toMustacheList(contextVariables.toList()),
    };
  }
}

/// Data for IRI strategy
class IriStrategyData {
  final IriTemplateData? template;
  // FIXME: support non-template IRIs (aka custom mappers)

  const IriStrategyData({
    this.template,
  });

  Map<String, dynamic> toMap() => {
        'hasTemplate': template != null,
        'template': template?.toMap(),
      };
}

/// Data for IRI parts parsing
@Deprecated('used?')
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
@Deprecated("rewrite")
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
@Deprecated("rewrite")
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
