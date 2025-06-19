import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/iri_processor_test_models.dart';
import '../fixtures/iri_processor_test_models.rdf_mapper.g.dart';
import '../test_helper.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  setupTestLogging();

  const testSubject = IriTerm.prevalidated('https://example.org/subject');
  const testPredicate = IriTerm.prevalidated('https://example.org/predicate');

  late RdfMapper mapper;

  IriTerm serialize<T>(T value, {RdfMapperRegistry? registry}) {
    final context =
        SerializationContextImpl(registry: registry ?? mapper.registry);
    // Test serialization
    final graph = context.value(testSubject, testPredicate, value);
    final triple = graph.single;
    return triple.object as IriTerm;
  }

  T deserialize<T>(IriTerm term, {RdfMapperRegistry? registry}) {
    final graph =
        RdfGraph.fromTriples([Triple(testSubject, testPredicate, term)]);
    final context = DeserializationContextImpl(
        graph: graph, registry: registry ?? mapper.registry);
    // Test deserialization
    return context.deserialize(term, null, null, null, null);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testIriMapper: NamedTestIriMapper(),
    );
  });

  group('All Iri Mappers Test', () {
    test('IriWithOnePart mapping', () {
      // Verify global resource registration

      expect(isRegisteredIriTermMapper<IriWithOnePart>(mapper), isTrue,
          reason: 'IriWithOnePart should be registered as a iri term mapper');

      // Create a Book instance
      final value = IriWithOnePart(
        isbn: '1234567890',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('<http://example.org/books/1234567890>'));

      // Test deserialization
      final deserialized = deserialize<IriWithOnePart>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(value.isbn));
    });

    test('IriWithOnePartExplicitlyGlobal mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithOnePartExplicitlyGlobal>(mapper),
          isTrue,
          reason:
              'IriWithOnePartExplicitlyGlobal should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithOnePartExplicitlyGlobal(
        isbn: '9876543210',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('<http://example.org/books/9876543210>'));

      // Test deserialization
      final deserialized = deserialize<IriWithOnePartExplicitlyGlobal>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(value.isbn));
    });

    test('IriWithOnePartNamed mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithOnePartNamed>(mapper), isTrue,
          reason:
              'IriWithOnePartNamed should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithOnePartNamed(
        value: 'test-book-123',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(
          term.toString(), equals('<http://example.org/books/test-book-123>'));

      // Test deserialization
      final deserialized = deserialize<IriWithOnePartNamed>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('IriWithTwoParts mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithTwoParts>(mapper), isTrue,
          reason: 'IriWithTwoParts should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithTwoParts(
        value: 'test-item',
        type: 'products',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(
          term.toString(), equals('<http://example.org/products/test-item>'));

      // Test deserialization
      final deserialized = deserialize<IriWithTwoParts>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
      expect(deserialized.type, equals(value.type));
    });

    test('IriWithBaseUriAndTwoParts mapping', () {
      // Verify global resource registration
      expect(
          isRegisteredIriTermMapper<IriWithBaseUriAndTwoParts>(mapper), isTrue,
          reason:
              'IriWithBaseUriAndTwoParts should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithBaseUriAndTwoParts(
        value: 'test-value',
        otherPart: 'categories',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(),
          equals('<http://example.org/categories/test-value>'));

      // Test deserialization
      final deserialized = deserialize<IriWithBaseUriAndTwoParts>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
      expect(deserialized.otherPart, equals(value.otherPart));
    });

    test('IriWithBaseUri mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithBaseUri>(mapper), isTrue,
          reason: 'IriWithBaseUri should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithBaseUri(
        isbn: 'base-test-123',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(
          term.toString(), equals('<http://example.org/books/base-test-123>'));

      // Test deserialization
      final deserialized = deserialize<IriWithBaseUri>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(value.isbn));
    });

    test('IriWithBaseUriNoGlobal mapping', () {
      // Verify this is NOT registered as a global mapper (false parameter)
      expect(isRegisteredIriTermMapper<IriWithBaseUriNoGlobal>(mapper), isFalse,
          reason:
              'IriWithBaseUriNoGlobal should NOT be registered as a global iri term mapper');

      // Test with explicit registry that includes this mapper
      final customRegistry = mapper.registry.clone();
      customRegistry.registerMapper(IriWithBaseUriNoGlobalMapper(
        baseUriProvider: () => 'http://example.org',
      ));

      // Create an instance
      final value = IriWithBaseUriNoGlobal(
        isbn: 'no-global-123',
      );

      final term = serialize(value, registry: customRegistry);
      expect(term, isNotNull);
      expect(
          term.toString(), equals('<http://example.org/books/no-global-123>'));

      // Test deserialization
      final deserialized =
          deserialize<IriWithBaseUriNoGlobal>(term, registry: customRegistry);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(value.isbn));
    });

    test('IriWithNamedMapper mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithNamedMapper>(mapper), isTrue,
          reason:
              'IriWithNamedMapper should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithNamedMapper('http://example.org/test-named-value');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('<http://example.org/test-named-value>'));

      // Test deserialization
      final deserialized = deserialize<IriWithNamedMapper>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('IriWithMapper mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithMapper>(mapper), isTrue,
          reason: 'IriWithMapper should be registered as a iri term mapper');

      // Create an instance
      final value = IriWithMapper('http://example.org/test-mapper-value');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('<http://example.org/test-mapper-value>'));

      // Test deserialization
      final deserialized = deserialize<IriWithMapper>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('IriWithMapperInstance mapping', () {
      // Verify global resource registration
      expect(isRegisteredIriTermMapper<IriWithMapperInstance>(mapper), isTrue,
          reason:
              'IriWithMapperInstance should be registered as a iri term mapper');

      // Create an instance
      final value =
          IriWithMapperInstance('http://example.org/test-instance-value');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(
          term.toString(), equals('<http://example.org/test-instance-value>'));

      // Test deserialization
      final deserialized = deserialize<IriWithMapperInstance>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });
  });
}

bool isRegisteredIriTermMapper<T>(RdfMapper mapper) {
  return mapper.registry.hasIriTermDeserializerFor<T>() &&
      mapper.registry.hasIriTermSerializerFor<T>();
}
