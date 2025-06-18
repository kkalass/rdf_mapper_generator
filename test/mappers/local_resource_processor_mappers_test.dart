import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/local_resource_processor_test_models.dart';
import '../fixtures/local_resource_processor_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('All Mappers Test', () {
    test('Book mapping', () {
      // Verify local resource registration
      final isRegistered =
          mapper.registry.hasLocalResourceDeserializerFor<Book>();
      expect(isRegistered, isTrue,
          reason: 'Book should be registered as a local resource');
      final isRegisteredAsGlobal =
          mapper.registry.hasGlobalResourceDeserializerFor<Book>();
      expect(isRegisteredAsGlobal, isFalse,
          reason: 'Book should not be registered as a global resource');

      // Create a Book instance
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

    test('ClassNoRegisterGlobally mapping', () {
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>();
      expect(isRegistered, isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassNoRegisterGlobally(name: 'no-register');

      // Test serialization - should fail with SerializerNotFoundException
      expect(() => mapper.encodeObject(instance),
          throwsA(isA<SerializerNotFoundException>()));
      final graph = """
@prefix schema: <https://schema.org/> .

_:b0 a schema:Person;
    schema:name "no-register" .
""";
      // Test deserialization - should fail with DeserializerNotFoundException
      expect(() => mapper.decodeObject<ClassNoRegisterGlobally>(graph),
          throwsA(isA<DeserializerNotFoundException>()));
    });

    test('ClassNoRegisterGlobally mapping explicitly registered', () {
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassNoRegisterGlobally(name: 'no-register');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) =>
              registry.registerMapper(ClassNoRegisterGloballyMapper()));
      expect(graph, isNotNull);
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');

      // Test deserialization
      final deserialized = mapper.decodeObject<ClassNoRegisterGlobally>(graph,
          register: (registry) =>
              registry.registerMapper(ClassNoRegisterGloballyMapper()));
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(instance.name));
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');
    });
  });
}
