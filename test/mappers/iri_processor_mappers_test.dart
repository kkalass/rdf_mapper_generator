import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/iri_processor_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
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
  });
}

bool isRegisteredIriTermMapper<T>(RdfMapper mapper) {
  return mapper.registry.hasIriTermDeserializerFor<T>() &&
      mapper.registry.hasIriTermSerializerFor<T>();
}
