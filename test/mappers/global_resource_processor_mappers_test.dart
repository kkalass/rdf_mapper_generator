import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/global_resource_processor_test_models.dart';
// Import the generated init function
import '../init_test_rdf_mapper.g.dart';

class TestMapper implements IriTermMapper<ClassWithIriNamedMapperStrategy> {
  @override
  ClassWithIriNamedMapperStrategy fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(
      ClassWithIriNamedMapperStrategy value, SerializationContext context) {
    throw UnimplementedError();
  }
}

void main() {
  late RdfMapper mapper;
  const baseUri = 'http://example.org/';

  setUp(() {
    mapper = initTestRdfMapper(
      baseUriProvider: () => baseUri,
      testMapper: TestMapper(),
    );
  });

  group('All Mappers Test', () {
    test('Book mapping', () {
      final book = Book(
        isbn: '1234567890',
        title: 'Test Book',
        authorId: 'author123',
      );

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<Book>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(book.isbn));
      expect(deserialized.title, equals(book.title));
      expect(deserialized.authorId, equals(book.authorId));
    });

    test('ClassWithIriTemplateStrategy mapping', () {
      final instance = ClassWithIriTemplateStrategy(id: 'template-strategy');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithIriTemplateStrategy>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithIriTemplateAndContextVariableStrategy mapping', () {
      final instance =
          ClassWithIriTemplateAndContextVariableStrategy(id: 'context-var');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper
          .decodeObject<ClassWithIriTemplateAndContextVariableStrategy>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithEmptyIriStrategy mapping', () {
      final instance = ClassWithEmptyIriStrategy(iri: "http://example.org/");
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
    });

    test('ClassWithIriNamedMapperStrategy mapping', () {
      final instance = ClassWithIriNamedMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
    });

    test('ClassWithIriMapperStrategy mapping', () {
      final instance = ClassWithIriMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
    });

    test('ClassWithIriMapperInstanceStrategy mapping', () {
      final instance = ClassWithIriMapperInstanceStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
    });
  });
}
