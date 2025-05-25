import 'package:build/build.dart';
import 'package:rdf_mapper_generator/builder.dart';
import 'package:test/test.dart';

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
