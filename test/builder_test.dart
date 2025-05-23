import 'package:rdf_mapper_generator/builder.dart';
import 'package:rdf_mapper_generator/src/builders/resource_builder.dart';
import 'package:test/test.dart';
import 'package:build/build.dart';

void main() {
  group('Builder Tests', () {
    test('rdfMapperBuilder returns an instance of RdfMapperBuilder', () {
      // Create dummy BuilderOptions
      final builderOptions = BuilderOptions({});
      final builder = rdfMapperBuilder(builderOptions);
      expect(builder, isA<RdfMapperBuilder>());
    });
  });
}
