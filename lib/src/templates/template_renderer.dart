import 'package:build/build.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;

/// Renders mustache templates for RDF mapper generation.
class TemplateRenderer {
  static final _instance = TemplateRenderer._();

  /// Cached templates
  final Map<String, Future<Template>> _templateCache = {};

  TemplateRenderer._();

  factory TemplateRenderer() => _instance;

  /// Renders a global resource mapper using the provided template data.
  Future<String> _renderGlobalResourceMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('global_resource_mapper', reader);
    return template.renderString(data);
  }

  Future<String> renderInitFileTemplate(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('init_rdf_mapper', reader);
    return template.renderString(data);
  }

  /// Renders a complete file using the file template and multiple mappers.
  Future<String> renderFileTemplate(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('file_template', reader);

    // Render each mapper individually first
    final renderedMappers = <String>[];
    for (final mapperData in data['mappers']) {
      final mapperCode = switch (mapperData['__type__']) {
        'GlobalResourceMapperTemplateData' => await _renderGlobalResourceMapper(
            mapperData as Map<String, dynamic>, reader),
        // Custom mappers are coded by our users, we do not render them here
        'GlobalResourceMapperCustomTemplateData' => null,
        // Add cases for other mapper types if needed
        _ => throw Exception('Unknown mapper type: ${mapperData['__type__']}'),
      };
      if (mapperCode == null) {
        continue; // Skip if the mapper code is null (e.g., custom mappers)
      }
      renderedMappers.add(mapperCode);
    }

    // Build the complete file data map

    data['mappers'] =
        renderedMappers.map((code) => {'mapperCode': code}).toList();

    final result = template.renderString(data);
    return result;
  }

  /// Gets a template by name, loading and caching it if necessary.
  Future<Template> _getTemplate(
          String templateName, AssetReader reader) async =>
      _templateCache.putIfAbsent(
          templateName,
          () async => Template(await _loadTemplate(templateName, reader),
              name: templateName,
              lenient: true,
              htmlEscapeValues: false)); // Disable HTML escaping globally

  Future<String> _loadTemplate(String name, AssetReader reader) async {
    final assetId = AssetId(
      'rdf_mapper_generator',
      path.join(
        'lib',
        'src',
        'templates',
        '$name.mustache',
      ),
    );
    return await reader.readAsString(assetId);
  }
}
