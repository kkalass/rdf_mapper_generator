import 'package:build/build.dart';
import 'package:rdf_mapper_generator/cache_builder.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperCacheBuilder Tests', () {
    late RdfMapperCacheBuilder builder;

    setUp(() {
      builder = RdfMapperCacheBuilder();
    });

    test('constructor creates a valid builder instance', () {
      expect(builder, isA<RdfMapperCacheBuilder>());
      expect(builder, isA<Builder>());
    });

    test('buildExtensions returns correct mapping', () {
      final extensions = builder.buildExtensions;
      expect(extensions, isA<Map<String, List<String>>>());
      expect(extensions['.dart'], equals(['.rdf_mapper.cache.json']));
    });

    test('rdfMapperCacheBuilder factory returns correct instance', () {
      final builderOptions = BuilderOptions({});
      final factoryBuilder = rdfMapperCacheBuilder(builderOptions);
      expect(factoryBuilder, isA<RdfMapperCacheBuilder>());
    });

    // The following tests use actual file analysis which requires full build environment
    // These can be considered integration tests and may need proper build configuration
    
    test('build method exists and accepts BuildStep', () {
      // This test verifies the method signature without actually executing the build
      expect(builder.build, isA<Function>());
      expect(builder.buildExtensions, isNotEmpty);
    });

    test('build extensions configuration is correct', () {
      final extensions = builder.buildExtensions;
      expect(extensions.keys, contains('.dart'));
      expect(extensions['.dart'], contains('.rdf_mapper.cache.json'));
    });

    test('factory method creates builder with options', () {
      final options = BuilderOptions({'test': 'value'});
      final factoryBuilder = rdfMapperCacheBuilder(options);
      
      expect(factoryBuilder, isA<RdfMapperCacheBuilder>());
      expect(factoryBuilder.buildExtensions, equals(builder.buildExtensions));
    });

    test('builder has correct build extensions mapping', () {
      expect(builder.buildExtensions, hasLength(1));
      expect(builder.buildExtensions.keys.first, equals('.dart'));
      expect(builder.buildExtensions.values.first, equals(['.rdf_mapper.cache.json']));
    });
  });
}
