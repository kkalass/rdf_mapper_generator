import 'package:mustache_template/mustache_template.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';

/// Renders mustache templates for RDF mapper generation.
class TemplateRenderer {
  static final _instance = TemplateRenderer._();

  /// Cached templates
  final Map<String, Template> _templateCache = {};

  TemplateRenderer._();

  factory TemplateRenderer() => _instance;

  /// Renders a global resource mapper using the provided template data.
  String renderGlobalResourceMapper(GlobalResourceMapperTemplateData data) {
    final template = _getTemplate('global_resource_mapper');
    return template.renderString(data.toMap());
  }

  /// Gets a template by name, loading and caching it if necessary.
  Template _getTemplate(String templateName) {
    return _templateCache.putIfAbsent(templateName, () {
      final templateContent = _loadTemplate(templateName);
      return Template(templateContent);
    });
  }

  /// Loads template content from the templates directory.
  String _loadTemplate(String templateName) {
    // In a real implementation, we'd load this from package resources
    // For now, we'll use the embedded template content
    switch (templateName) {
      case 'global_resource_mapper':
        return _globalResourceMapperTemplate;
      default:
        throw ArgumentError('Unknown template: $templateName');
    }
  }

  // Embedded template content (in a real implementation, this would be loaded from files)
  static const String _globalResourceMapperTemplate = '''
{{#imports}}
import '{{{import}}}';
{{/imports}}

/// Generated mapper for [{{className}}] global resources.
/// 
/// This mapper handles serialization and deserialization between Dart objects
/// and RDF triples for resources of type {{className}}.
class {{mapperClassName}} implements GlobalResourceMapper<{{className}}> {
  @override
  IriTerm get typeIri => {{typeIri}};

  @override
  {{className}} fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    
    {{#iriParts}}
    {{#hasTemplate}}
    // Extract IRI parts
    final iriTemplate = '{{template}}';
    final iriParts = _parseIriParts(subject.value, iriTemplate);
    {{/hasTemplate}}
    {{/iriParts}}
    
    {{#constructorParameters}}
    {{#isIriPart}}
    final {{name}} = {{#hasConverter}}{{converter}}.fromIri({{/hasConverter}}{{^hasConverter}}{{/hasConverter}}iriParts['{{iriPartName}}']{{#hasConverter}}){{/hasConverter}};
    {{/isIriPart}}
    {{#isRdfProperty}}
    final {{name}} = reader.{{#isRequired}}require{{/isRequired}}{{^isRequired}}get{{/isRequired}}<{{dartType}}>({{predicate}}){{#hasDefaultValue}} ?? {{defaultValue}}{{/hasDefaultValue}};
    {{/isRdfProperty}}
    {{/constructorParameters}}

    return {{className}}(
      {{#constructorParameters}}
      {{name}}: {{name}},
      {{/constructorParameters}}
    );
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
    {{className}} resource,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    {{#iriStrategy}}
    final subject = {{#hasTemplate}}IriTerm(_buildIri(resource)){{/hasTemplate}}{{^hasTemplate}}IriTerm('{{baseIri}}'){{/hasTemplate}};
    {{/iriStrategy}}
    
    final builder = context.resourceBuilder(subject);
    
    {{#properties}}
    {{#isRdfProperty}}
    {{#isRequired}}
    builder.addValue({{predicate}}, {{#hasConverter}}{{converter}}.toRdf({{/hasConverter}}resource.{{propertyName}}{{#hasConverter}}){{/hasConverter}});
    {{/isRequired}}
    {{^isRequired}}
    if (resource.{{propertyName}} != null) {
      builder.addValue({{predicate}}, {{#hasConverter}}{{converter}}.toRdf({{/hasConverter}}resource.{{propertyName}}{{#hasConverter}}){{/hasConverter}});
    }
    {{/isRequired}}
    {{/isRdfProperty}}
    {{/properties}}

    return builder.build();
  }

  {{#iriStrategy}}
  {{#hasTemplate}}
  /// Builds the IRI for a resource instance using the IRI template.
  String _buildIri({{className}} resource) {
    var iri = '{{template}}';
    {{#iriParts}}
    iri = iri.replaceAll('{{{placeholder}}}', {{#hasConverter}}{{converter}}.toIri({{/hasConverter}}resource.{{propertyName}}.toString(){{#hasConverter}}){{/hasConverter}});
    {{/iriParts}}
    return iri;
  }

  /// Parses IRI parts from a complete IRI using the template.
  Map<String, String> _parseIriParts(String iri, String template) {
    final parts = <String, String>{};
    // Simple template parsing - in practice, this would be more sophisticated
    {{#iriParts}}
    // Extract {{placeholder}} from IRI
    final {{propertyName}}Pattern = RegExp(r'{{regexPattern}}');
    final {{propertyName}}Match = {{propertyName}}Pattern.firstMatch(iri);
    if ({{propertyName}}Match != null) {
      parts['{{placeholder}}'] = {{propertyName}}Match.group(1)!;
    }
    {{/iriParts}}
    return parts;
  }
  {{/hasTemplate}}
  {{/iriStrategy}}
}
''';
}
