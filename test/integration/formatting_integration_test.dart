import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/utils/dart_formatter.dart';
import 'package:build_test/build_test.dart';

void main() {
  group('Template Formatting Integration', () {
    late TemplateRenderer renderer;

    setUp(() {
      renderer = TemplateRenderer();
    });

    test('should format complex generated file template', () async {
      // Create complex template data that would generate unformatted code
      final templateData = {
        'header': {
          'sourcePath': 'test/models.dart',
          'generatedOn': '2024-01-01T00:00:00.000Z',
        },
        'broaderImports': {},
        'mappers': [
          {
            '__type__': 'ResourceMapperTemplateData',
            'className': {
              'code': 'TestClass',
              'imports': [],
              '__type__': '\$Code\$'
            },
            'mapperClassName': {
              'code': 'TestClassMapper',
              'imports': [],
              '__type__': '\$Code\$'
            },
            'mapperInterfaceName': {
              'code': 'GlobalResourceMapper',
              'imports': ['package:rdf_mapper/rdf_mapper.dart'],
              '__type__': '\$Code\$'
            },
            'termClass': {
              'code': 'IriTerm',
              'imports': [],
              '__type__': '\$Code\$'
            },
            'typeIri': null,
            'hasTypeIri': false,
            'hasIriStrategy': false,
            'hasIriStrategyMapper': false,
            'iriStrategy': null,
            'contextProviders': [],
            'hasContextProviders': false,
            'hasLateMapperConstructorParameters': false,
            'hasMapperConstructorBody': false,
            'hasMapperConstructorParameterAssignments': false,
            'hasMapperConstructorParameters': false,
            'constructorParameters': [],
            'nonConstructorFields': [],
            'hasNonConstructorFields': false,
            'constructorParametersOrOtherFields': [],
            'properties': [
              {
                'propertyName': 'title',
                'dartType': {
                  'code': 'String',
                  'imports': [],
                  '__type__': '\$Code\$'
                },
                'predicate': {
                  'code': 'Schema.name',
                  'imports': ['package:rdf_vocabularies/schema.dart'],
                  '__type__': '\$Code\$'
                },
                'isRequired': true,
                'isRdfProperty': true,
              }
            ],
            'needsReader': true,
            'registerGlobally': true,
          }
        ],
      };

      final reader = await PackageAssetReader.currentIsolate();
      final result = await renderer.renderFileTemplate(
        'package:test/models.rdf_mapper.g.dart',
        templateData,
        reader,
      );

      // Verify the result is properly formatted
      expect(result, isNotEmpty);
      expect(result, contains('class TestClassMapper'));
      expect(result, contains('  @override'));
      expect(result, contains('    final reader'));

      // Verify it can be parsed as valid Dart code (no syntax errors)
      final formatter = DartCodeFormatter();
      expect(() => formatter.formatCode(result), returnsNormally);

      // Check for proper indentation patterns
      final lines = result.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isNotEmpty) {
          // Check that indentation uses spaces, not tabs
          final leadingWhitespace =
              line.substring(0, line.length - line.trimLeft().length);
          expect(leadingWhitespace, isNot(contains('\t')),
              reason:
                  'Line ${i + 1} should use spaces for indentation, not tabs: "$line"');
        }
      }
    });

    test('should handle formatting errors gracefully', () {
      // Test with intentionally malformed template data that would generate invalid Dart
      const invalidCode = '''
class TestClass {
  String name
  // Missing semicolon should cause formatting to fail gracefully
}
''';

      final formatter = DartCodeFormatter();
      final result = formatter.formatCode(invalidCode);

      // Should return the original code when formatting fails
      expect(result, equals(invalidCode));
    });

    test('should preserve complex formatting in init files', () async {
      final templateData = {
        'generatedOn': '2024-01-01T00:00:00.000Z',
        'isTest': true,
        'mappers': [
          {
            'className': 'TestClass',
            'mapperClassName': 'TestClassMapper',
            'registerGlobally': true,
          }
        ],
        'providers': [
          {
            'parameterName': 'testProvider',
            'variableName': 'testVar',
            'privateFieldName': '_testField',
          }
        ],
        'hasProviders': true,
        'namedCustomMappers': [],
        'hasNamedCustomMappers': false,
      };

      final reader = await PackageAssetReader.currentIsolate();
      final result =
          await renderer.renderInitFileTemplate(templateData, reader);

      // Verify the result is properly formatted
      expect(result, isNotEmpty);
      expect(result, contains('RdfMapper initTestRdfMapper'));

      // Check for consistent indentation
      final lines = result.split('\n');
      bool foundFunctionSignature = false;
      for (final line in lines) {
        if (line.contains('initTestRdfMapper')) {
          foundFunctionSignature = true;
        }
        if (foundFunctionSignature && line.trim().startsWith('required ')) {
          // Parameter lines should be properly indented
          expect(line, startsWith('  '),
              reason:
                  'Function parameters should be indented with 2 spaces: "$line"');
        }
      }
    });
  });
}
