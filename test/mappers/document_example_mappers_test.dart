import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/rdf_mapper_annotations/examples/document_example.dart';
import '../fixtures/rdf_mapper_annotations/examples/document_example.rdf_mapper.g.dart';
import '../fixtures/comprehensive_collection_tests.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testMapper: TestMapper(),
    );
  });

  group('Document Example Mapper Tests', () {
    test('Document<Person> mapping with complex example data', () {
      // Verify it's NOT registered globally (registerGlobally: false)
      final isRegisteredGlobally =
          mapper.registry.hasGlobalResourceDeserializerFor<Document<Person>>();
      expect(isRegisteredGlobally, isFalse,
          reason: 'Document should not be registered globally');

      // Create a Person instance with realistic data
      final person = Person(
        name: 'Klas Kalaaß',
        preferencesFile: Uri.parse('/settings/prefs.ttl'),
        storage: Uri.parse('/'),
        account: Uri.parse('/'),
        oidcIssuer: Uri.parse('https://datapod.igrant.io'),
        privateTypeIndex: Uri.parse('/settings/privateTypeIndex.ttl'),
        publicTypeIndex: Uri.parse('/settings/publicTypeIndex.ttl'),
        other: RdfGraph(),
      );

      // Create a Document<Person> instance
      final document = Document<Person>(
        documentIri: './card',
        maker: Uri.parse('#me'),
        primaryTopic: person,
        unmapped: RdfGraph(),
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document, register: (registry) {
        registry.registerMapper(DocumentMapper<Person>(
          primaryTopicSerializationProvider:
              SerializationProvider.iriContextual((IriTerm iri) =>
                  PersonMapper(documentIriProvider: () => iri.iri)),
        ));
      });
      expect(graph, isNotNull);
      expect(graph, contains('Klas Kalaaß'));
      expect(graph, contains('datapod.igrant.io'));
      expect(graph, contains('privateTypeIndex'));
      expect(graph, contains('publicTypeIndex'));
      expect(graph, contains('./card'));

      // Test deserialization with explicit registration
      final deserialized =
          mapper.decodeObject<Document<Person>>(graph, register: (registry) {
        registry.registerMapper(createPersonDocumentMapper());
      });
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.maker, equals(document.maker));
      expect(deserialized.primaryTopic.name, equals(person.name));
      expect(deserialized.primaryTopic.oidcIssuer, equals(person.oidcIssuer));
    });

    test('Document<String> mapping with string primary topic', () {
      // Test Document with a simple string as primary topic
      final document = Document<String>(
        documentIri: 'http://example.org/simple-doc',
        maker: Uri.parse('http://example.org/maker'),
        primaryTopic: 'Simple String Topic',
        unmapped: RdfGraph(),
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          register: (registry) => registry.registerMapper(
              DocumentMapper<String>(
                  primaryTopicSerializationProvider:
                      SerializationProvider.nonContextual(StringMapper()))));
      expect(graph, isNotNull);
      expect(graph, contains('Simple String Topic'));
      expect(graph, contains('http://example.org/simple-doc'));
      expect(graph, contains('http://example.org/maker'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<Document<String>>(graph,
          register: (registry) => registry.registerMapper(
              DocumentMapper<String>(
                  primaryTopicSerializationProvider:
                      SerializationProvider.nonContextual(StringMapper()))));
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.maker, equals(document.maker));
      expect(deserialized.primaryTopic, equals(document.primaryTopic));
    });

    test('Person mapping as standalone resource', () {
      // Verify Person is NOT registered globally (registerGlobally: false)
      final isRegisteredGlobally =
          mapper.registry.hasGlobalResourceDeserializerFor<Person>();
      expect(isRegisteredGlobally, isFalse,
          reason: 'Person should not be registered globally');

      // Create a Person instance with comprehensive data
      final person = Person(
        name: 'John Doe',
        preferencesFile: Uri.parse('/user/settings/preferences.ttl'),
        storage: Uri.parse('/user/storage/'),
        account: Uri.parse('/user/account/'),
        oidcIssuer: Uri.parse('https://auth.example.com'),
        privateTypeIndex: Uri.parse('/user/settings/private-index.ttl'),
        publicTypeIndex: Uri.parse('/user/settings/public-index.ttl'),
        other: RdfGraph(),
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(person,
          register: (registry) => registry.registerMapper(PersonMapper(
              documentIriProvider: () => 'https://example.com/johndoe')));
      expect(graph, isNotNull);
      expect(graph, contains('John Doe'));
      expect(graph, contains('auth.example.com'));
      expect(graph, contains('preferences.ttl'));
      expect(graph, contains('private-index.ttl'));
      expect(graph, contains('public-index.ttl'));
      expect(graph, contains('storage'));
      expect(graph, contains('account'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<Person>(graph,
          register: (registry) => registry.registerMapper(PersonMapper(
              documentIriProvider: () => 'https://example.com/johndoe')));
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(person.name));
      expect(deserialized.preferencesFile, equals(person.preferencesFile));
      expect(deserialized.storage, equals(person.storage));
      expect(deserialized.account, equals(person.account));
      expect(deserialized.oidcIssuer, equals(person.oidcIssuer));
      expect(deserialized.privateTypeIndex, equals(person.privateTypeIndex));
      expect(deserialized.publicTypeIndex, equals(person.publicTypeIndex));
    });

    test('Document with real turtle example data parsing', () {
      // Use the actual turtle document from the example file
      const realTurtleData = '''
@prefix : <#>.
@prefix foaf: <http://xmlns.com/foaf/0.1/>.
@prefix schema: <http://schema.org/>.
@prefix solid: <http://www.w3.org/ns/solid/terms#>.
@prefix space: <http://www.w3.org/ns/pim/space#>.
@prefix pro: <./>.
@prefix kk: </>.

pro:card a foaf:PersonalProfileDocument; foaf:maker :me; foaf:primaryTopic :me.

:me
    a schema:Person, foaf:Person;
    space:preferencesFile </settings/prefs.ttl>;
    space:storage kk:;
    solid:account kk:;
    solid:oidcIssuer <https://datapod.igrant.io>;
    solid:privateTypeIndex </settings/privateTypeIndex.ttl>;
    solid:publicTypeIndex </settings/publicTypeIndex.ttl>;
    foaf:name "Klas Kalaaß".
''';

      // Test deserialization from real turtle data
      final deserialized = mapper.decodeObject<Document<Person>>(realTurtleData,
          register: (registry) {
        registry.registerMapper(createPersonDocumentMapper());
      });

      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals('./card'));
      expect(deserialized.maker, equals(Uri.parse('#me')));
      expect(deserialized.primaryTopic.name, equals('Klas Kalaaß'));
      expect(deserialized.primaryTopic.oidcIssuer,
          equals(Uri.parse('https://datapod.igrant.io')));
      expect(deserialized.primaryTopic.storage, equals(Uri.parse('/')));
      expect(deserialized.primaryTopic.account, equals(Uri.parse('/')));
      expect(deserialized.primaryTopic.preferencesFile,
          equals(Uri.parse('/settings/prefs.ttl')));
      expect(deserialized.primaryTopic.privateTypeIndex,
          equals(Uri.parse('/settings/privateTypeIndex.ttl')));
      expect(deserialized.primaryTopic.publicTypeIndex,
          equals(Uri.parse('/settings/publicTypeIndex.ttl')));
    });

    test('Document<int> mapping with numeric primary topic', () {
      // Test Document with numeric primary topic
      final document = Document<int>(
        documentIri: 'http://example.org/numeric-doc',
        maker: Uri.parse('http://example.org/numeric-maker'),
        primaryTopic: 42,
        unmapped: RdfGraph(),
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          register: (registry) => registry.registerMapper(DocumentMapper<int>(
              primaryTopicSerializationProvider:
                  SerializationProvider.nonContextual(IntMapper()))));
      expect(graph, isNotNull);
      expect(graph, contains('42'));
      expect(graph, contains('http://example.org/numeric-doc'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<Document<int>>(graph,
          register: (registry) => registry.registerMapper(DocumentMapper<int>(
              primaryTopicSerializationProvider:
                  SerializationProvider.nonContextual(IntMapper()))));
      expect(deserialized, isNotNull);
      expect(deserialized.primaryTopic, equals(42));
      expect(deserialized.documentIri, equals(document.documentIri));
    });

    test('Document<List<String>> mapping with collection primary topic', () {
      // Test Document with collection as primary topic
      final document = Document<List<String>>(
        documentIri: 'http://example.org/list-doc',
        maker: Uri.parse('http://example.org/list-maker'),
        primaryTopic: ['topic1', 'topic2', 'topic3'],
        unmapped: RdfGraph(),
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          register: (registry) => registry.registerMapper(DocumentMapper<
                  List<String>>(
              primaryTopicSerializationProvider:
                  SerializationProvider.nonContextual(StringListMapper()))));
      expect(graph, isNotNull);
      expect(graph, contains('http://example.org/list-doc'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<Document<List<String>>>(graph,
          register: (registry) => registry.registerMapper(DocumentMapper<
                  List<String>>(
              primaryTopicSerializationProvider:
                  SerializationProvider.nonContextual(StringListMapper()))));
      expect(deserialized, isNotNull);
      expect(deserialized.primaryTopic, equals(['topic1', 'topic2', 'topic3']));
      expect(deserialized.documentIri, equals(document.documentIri));
    });

    test('Registration behavior verification', () {
      // Verify that both Document and Person are not auto-registered
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<Document<Person>>(),
          isFalse,
          reason: 'Document should not be registered globally');
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<Person>(), isFalse,
          reason: 'Person should not be registered globally');

      // Test that serialization fails without explicit registration
      final document = Document<String>(
        documentIri: 'test',
        maker: Uri.parse('test'),
        primaryTopic: 'test',
        unmapped: RdfGraph(),
      );

      expect(() => mapper.encodeObject(document),
          throwsA(isA<SerializerNotFoundException>()));

      final person = Person(
        name: 'test',
        preferencesFile: Uri.parse('test'),
        storage: Uri.parse('test'),
        account: Uri.parse('test'),
        oidcIssuer: Uri.parse('test'),
        privateTypeIndex: Uri.parse('test'),
        publicTypeIndex: Uri.parse('test'),
        other: RdfGraph(),
      );

      expect(() => mapper.encodeObject(person),
          throwsA(isA<SerializerNotFoundException>()));
    });

    test('RdfUnmappedTriples functionality', () {
      // Test that unmapped triples are properly handled
      final person = Person(
        name: 'Test Person',
        preferencesFile: Uri.parse('/prefs.ttl'),
        storage: Uri.parse('/'),
        account: Uri.parse('/'),
        oidcIssuer: Uri.parse('https://example.com'),
        privateTypeIndex: Uri.parse('/private.ttl'),
        publicTypeIndex: Uri.parse('/public.ttl'),
        other: RdfGraph(),
      );

      final document = Document<Person>(
        documentIri: 'http://example.org/unmapped-test',
        maker: Uri.parse('#maker'),
        primaryTopic: person,
        unmapped: RdfGraph(),
      );

      // Test serialization preserves unmapped triples structure
      final graph = mapper.encodeObject(document, register: (registry) {
        registry.registerMapper(createPersonDocumentMapper());
      });
      expect(graph, isNotNull);

      // Test deserialization handles unmapped triples
      final deserialized =
          mapper.decodeObject<Document<Person>>(graph, register: (registry) {
        registry.registerMapper(createPersonDocumentMapper());
      });
      expect(deserialized, isNotNull);
      expect(deserialized.unmapped, isA<RdfGraph>());
      expect(deserialized.primaryTopic.other, isA<RdfGraph>());
    });

    test('RdfProvides annotation functionality', () {
      // Test that @RdfProvides on documentIri works correctly
      final document = Document<String>(
        documentIri: 'http://example.org/provides-test',
        maker: Uri.parse('#maker'),
        primaryTopic: 'Provides Test Topic',
        unmapped: RdfGraph(),
      );

      // Test serialization
      final graph = mapper.encodeObject(document,
          register: (registry) => registry.registerMapper(
              DocumentMapper<String>(
                  primaryTopicSerializationProvider:
                      SerializationProvider.nonContextual(StringMapper()))));
      expect(graph, isNotNull);
      expect(graph, contains('http://example.org/provides-test'));

      // Test deserialization ensures documentIri is provided correctly
      final deserialized = mapper.decodeObject<Document<String>>(graph,
          register: (registry) => registry.registerMapper(
              DocumentMapper<String>(
                  primaryTopicSerializationProvider:
                      SerializationProvider.nonContextual(StringMapper()))));
      expect(deserialized, isNotNull);
      expect(
          deserialized.documentIri, equals('http://example.org/provides-test'));
    });
  });
}

DocumentMapper<Person> createPersonDocumentMapper() {
  return DocumentMapper<Person>(
    primaryTopicSerializationProvider: SerializationProvider.iriContextual(
        (IriTerm iri) => PersonMapper(documentIriProvider: () => iri.iri)),
  );
}
