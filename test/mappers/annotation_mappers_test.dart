import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/annotation_test_models.dart';
// Import the generated init function
import '../fixtures/annotation_test_models.rdf_mapper.g.dart';
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

class TestIriTermRecordMapper implements IriTermMapper<(String id,)> {
  final String baseUri;

  TestIriTermRecordMapper(this.baseUri);

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.iri;
    final lastSlashIndex = uri.lastIndexOf('/');
    if (lastSlashIndex == -1 || lastSlashIndex == uri.length - 1) {
      throw ArgumentError('Invalid IRI format: cannot extract ID from $uri');
    }
    final id = uri.substring(lastSlashIndex + 1);
    return (id,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    final id = value.$1;
    final uri = baseUri.endsWith('/') ? '$baseUri$id' : '$baseUri/$id';
    return IriTerm(uri);
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

    test('BookWithMapperInstance mapping registered manually', () {
      final book = BookWithMapperInstance('456');
      final iriTermMapper = TestIriTermRecordMapper('http://example.org/book/');
      final globalResourceMapper =
          BookWithMapperInstanceMapper(iriMapper: iriTermMapper);

      // Test serialization
      final graph = mapper.encodeObject(book,
          register: (registry) =>
              registry.registerMapper(globalResourceMapper));
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithMapperInstance>(graph,
          register: (registry) =>
              registry.registerMapper(globalResourceMapper));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
    });

    test(
        'BookWithMapperInstance mapping throws exception due to missing global registration',
        () {
      final book = BookWithMapperInstance('456');

      // Test serialization - should throw SerializerNotFoundException
      expect(() => mapper.encodeObject(book),
          throwsA(isA<SerializerNotFoundException>()));
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
