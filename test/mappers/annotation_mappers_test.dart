import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/annotation_test_models.dart';
// Import the generated init function
import '../fixtures/global_resource_processor_test_models.dart';
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
        baseUriProvider: () => baseUri, testMapper: TestMapper());
  });

  group('All Mappers Test', () {
    test('BookWithMapper mapping', () {
      final book = BookWithMapper(
        id: '123',
        title: 'Test Book',
      );

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapperInstance mapping', () {
      final book = BookWithMapperInstance('456');

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithMapperInstance>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
    });

    test('BookWithTemplate mapping', () {
      final book = BookWithTemplate('789');

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithTemplate>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
    });
  });
}
