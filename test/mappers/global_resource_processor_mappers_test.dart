import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/global_resource_processor_test_models.dart';
import '../fixtures/global_resource_processor_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

bool isRegisteredGlobalResourceMapper<T>(RdfMapper mapper) {
  return mapper.registry.hasGlobalResourceDeserializerFor<T>() &&
      mapper.registry.hasResourceSerializerFor<T>();
}

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testMapper: TestMapper(),
    );
  });

  group('All Mappers Test', () {
    test('Book mapping', () {
      // Verify global resource registration
      final isRegistered =
          mapper.registry.hasGlobalResourceDeserializerFor<Book>();
      expect(isRegistered, isTrue,
          reason: 'Book should be registered as a global resource');
      final isRegisteredAsLocal =
          mapper.registry.hasLocalResourceDeserializerFor<Book>();
      expect(isRegisteredAsLocal, isFalse,
          reason: 'Book should not be registered as a local resource');

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

    test('ClassWithOtherBaseUriNonGlobal mapping', () {
      expect(isRegisteredGlobalResourceMapper(mapper), isFalse);
      final instance = ClassWithOtherBaseUriNonGlobal(id: 'context-var');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) =>
              registry.registerMapper(ClassWithOtherBaseUriNonGlobalMapper(
                otherBaseUriProvider: () => 'https://other.example.org',
              )));
      expect(graph, isNotNull);
      expect(graph, contains('https://other.example.org/persons/context-var'));
      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithOtherBaseUriNonGlobal>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithEmptyIriStrategy mapping', () {
      final instance = ClassWithEmptyIriStrategy(iri: "http://example.org/");
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded = mapper.decodeObject<ClassWithEmptyIriStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriNamedMapperStrategy mapping', () {
      final instance = ClassWithIriNamedMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded =
          mapper.decodeObject<ClassWithIriNamedMapperStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriMapperStrategy mapping', () {
      final instance = ClassWithIriMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded = mapper.decodeObject<ClassWithIriMapperStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriMapperInstanceStrategy mapping', () {
      final instance = ClassWithIriMapperInstanceStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded =
          mapper.decodeObject<ClassWithIriMapperInstanceStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassNoRegisterGlobally mapping', () {
      final isRegistered = mapper.registry.hasLocalResourceDeserializerFor<
          ClassWithEmptyIriStrategyNoRegisterGlobally>();
      expect(isRegistered, isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassWithEmptyIriStrategyNoRegisterGlobally(
          iri: 'https://example.org/no-register');

      // Test serialization - should fail with SerializerNotFoundException
      expect(() => mapper.encodeObject(instance),
          throwsA(isA<SerializerNotFoundException>()));
      final graph = """
@prefix ex: <https://example.org/> .
@prefix schema: <https://schema.org/> .

ex:no-register a schema:Person .
""";
      // Test deserialization - should fail with DeserializerNotFoundException
      expect(
          () => mapper
              .decodeObject<ClassWithEmptyIriStrategyNoRegisterGlobally>(graph),
          throwsA(isA<DeserializerNotFoundException>()));
    });

    test('ClassNoRegisterGlobally mapping explicitly registered', () {
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassWithEmptyIriStrategyNoRegisterGlobally(
          iri: 'https://example.org/no-register');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) => registry.registerMapper(
              ClassWithEmptyIriStrategyNoRegisterGloballyMapper()));
      expect(graph, isNotNull);
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');

      // Test deserialization
      final deserialized = mapper
          .decodeObject<ClassWithEmptyIriStrategyNoRegisterGlobally>(graph,
              register: (registry) => registry.registerMapper(
                  ClassWithEmptyIriStrategyNoRegisterGloballyMapper()));
      expect(deserialized, isNotNull);
      expect(deserialized.iri, equals(instance.iri));
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');
    });

    test('ClassWithNoRdfType mapping', () {
      // Verify global resource registration
      final isRegistered = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithNoRdfType>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithNoRdfType should be registered as a global resource');

      // Create a ClassWithNoRdfType instance
      final instance = ClassWithNoRdfType('John Doe', age: 30);
      instance.iri = 'http://example.org/persons/john';

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<ClassWithNoRdfType>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.iri, equals(instance.iri));
      expect(deserialized.name, equals(instance.name));
      expect(deserialized.age, equals(instance.age));
    });
  });
}
