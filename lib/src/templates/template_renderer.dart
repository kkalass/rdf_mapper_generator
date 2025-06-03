import 'package:build/build.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:rdf_mapper_generator/src/templates/template_data.dart';

/// Renders mustache templates for RDF mapper generation.
class TemplateRenderer {
  static final _instance = TemplateRenderer._();

  /// Cached templates
  final Map<String, Future<Template>> _templateCache = {};

  TemplateRenderer._();

  factory TemplateRenderer() => _instance;

  /// Renders a global resource mapper using the provided template data.
  Future<String> renderGlobalResourceMapper(
      GlobalResourceMapperTemplateData data, AssetReader reader) async {
    final template = await _getTemplate('global_resource_mapper', reader);
    final dataMap = data.toMap();

    // Debug: Print the data being passed to the template
    print('Rendering template with data:');
    _printMap(dataMap, '  ');

    final result = template.renderString(dataMap);

    // Debug: Print the rendered result
    print('Rendered template:');
    print(result);

    return result;
  }

  // Helper method to print a map for debugging
  void _printMap(Map<String, dynamic> map, String indent) {
    map.forEach((key, value) {
      if (value is Map) {
        print('$indent$key:');
        _printMap(value as Map<String, dynamic>, '$indent  ');
      } else if (value is List) {
        print('$indent$key: [${value.length} items]');
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map) {
            print('$indent  [$i]:');
            _printMap(value[i] as Map<String, dynamic>, '$indent    ');
          } else {
            print('$indent  [$i]: ${value[i]}');
          }
        }
      } else {
        print('$indent$key: $value');
      }
    });
  }

  /// Gets a template by name, loading and caching it if necessary.
  Future<Template> _getTemplate(
          String templateName, AssetReader reader) async =>
      _templateCache.putIfAbsent(
          templateName,
          () async => Template(await loadTemplate(templateName, reader),
              name: templateName,
              lenient: true,
              htmlEscapeValues: false)); // Disable HTML escaping globally

  Future<String> loadTemplate(String name, AssetReader reader) async {
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
