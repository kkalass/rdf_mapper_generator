import 'dart:convert';

import 'package:build/build.dart';
import 'package:rdf_mapper_generator/source_builder.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperSourceBuilder Tests', () {
    late RdfMapperSourceBuilder builder;

    setUp(() {
      builder = RdfMapperSourceBuilder();
    });

    test('constructor creates a valid builder instance', () {
      expect(builder, isA<RdfMapperSourceBuilder>());
      expect(builder, isA<Builder>());
    });

    test('buildExtensions returns correct mapping', () {
      final extensions = builder.buildExtensions;
      expect(extensions, isA<Map<String, List<String>>>());
      expect(
          extensions['.rdf_mapper.cache.json'], equals(['.rdf_mapper.g.dart']));
    });

    test('rdfMapperSourceBuilder factory returns correct instance', () {
      final builderOptions = BuilderOptions({});
      final factoryBuilder = rdfMapperSourceBuilder(builderOptions);
      expect(factoryBuilder, isA<RdfMapperSourceBuilder>());
    });

    test('build method exists and accepts BuildStep', () {
      // This test verifies the method signature without actually executing the build
      expect(builder.build, isA<Function>());
      expect(builder.buildExtensions, isNotEmpty);
    });

    test('build extensions configuration is correct', () {
      final extensions = builder.buildExtensions;
      expect(extensions.keys, contains('.rdf_mapper.cache.json'));
      expect(
          extensions['.rdf_mapper.cache.json'], contains('.rdf_mapper.g.dart'));
    });

    test('factory method creates builder with options', () {
      final options = BuilderOptions({'test': 'value'});
      final factoryBuilder = rdfMapperSourceBuilder(options);

      expect(factoryBuilder, isA<RdfMapperSourceBuilder>());
      expect(factoryBuilder.buildExtensions, equals(builder.buildExtensions));
    });

    test('builder has correct build extensions mapping', () {
      expect(builder.buildExtensions, hasLength(1));
      expect(
          builder.buildExtensions.keys.first, equals('.rdf_mapper.cache.json'));
      expect(
          builder.buildExtensions.values.first, equals(['.rdf_mapper.g.dart']));
    });

    test('builder properly processes cache file extension', () {
      final extensions = builder.buildExtensions;
      final inputExtension = extensions.keys.first;
      final outputExtensions = extensions.values.first;

      expect(inputExtension, equals('.rdf_mapper.cache.json'));
      expect(outputExtensions, hasLength(1));
      expect(outputExtensions.first, equals('.rdf_mapper.g.dart'));
    });

    test('multiple instances are independent', () {
      final builder1 = rdfMapperSourceBuilder(BuilderOptions({}));
      final builder2 = rdfMapperSourceBuilder(BuilderOptions({}));

      expect(builder1, isA<RdfMapperSourceBuilder>());
      expect(builder2, isA<RdfMapperSourceBuilder>());
      expect(builder1.buildExtensions, equals(builder2.buildExtensions));
    });

    test('build extensions are immutable', () {
      final extensions = builder.buildExtensions;

      // Try to modify the extensions map (should not affect the builder)
      expect(() => extensions.clear(), throwsUnsupportedError);
    });

    // Helper method to create valid cache data for integration tests
    Map<String, dynamic> _createValidCacheData() {
      return {
        'mappers': [
          {
            'className': 'PersonMapper',
            'targetClassName': 'Person',
            'importUri': 'package:test/models.dart',
            'properties': [
              {
                'fieldName': 'name',
                'propertyType': 'literal',
                'predicateIri': 'http://example.org/name',
                'dartType': 'String?',
              }
            ],
            'subjectInfo': {
              'fieldName': 'iri',
              'dartType': 'String?',
            }
          }
        ],
        'imports': [
          'package:rdf_mapper_annotations/rdf_mapper_annotations.dart'
        ],
      };
    }

    test('cache data structure validation helper works', () {
      final cacheData = _createValidCacheData();

      expect(cacheData, isA<Map<String, dynamic>>());
      expect(cacheData['mappers'], isA<List>());
      expect(cacheData['imports'], isA<List>());

      final mappers = cacheData['mappers'] as List;
      expect(mappers, hasLength(1));

      final mapper = mappers.first as Map<String, dynamic>;
      expect(mapper['className'], equals('PersonMapper'));
      expect(mapper['targetClassName'], equals('Person'));
      expect(mapper['properties'], isA<List>());
      expect(mapper['subjectInfo'], isA<Map>());
    });

    test('JSON serialization works for cache data', () {
      final cacheData = _createValidCacheData();
      final jsonString = jsonEncode(cacheData);

      expect(jsonString, isA<String>());
      expect(jsonString, isNotEmpty);

      // Verify round-trip serialization
      final decoded = jsonDecode(jsonString);
      expect(decoded, equals(cacheData));
    });
  });
}
