import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/property_processor_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('Property Processor Mappers Test', () {
    test('DeserializationOnlyPropertyTest - include: false behavior', () {
      // Create two instances with different names
      final instance1 = DeserializationOnlyPropertyTest(name: 'Name1');
      final instance2 = DeserializationOnlyPropertyTest(name: 'Name2');

      // Serialize both instances
      final serialized1 = mapper.encodeObject(instance1);
      final serialized2 = mapper.encodeObject(instance2);

      // Since the name property is excluded from serialization (include: false),
      // both serialized forms should be equivalent even though the names are different
      expect(serialized1, equals(serialized2),
          reason:
              'Serialized forms should be identical when properties with include: false have different values');

      // When all properties are excluded from serialization, the result may be empty
      // This is the expected behavior for include: false
    });

    test(
        'SimplePropertyTest - normal property behavior (include: true by default)',
        () {
      // Create a test instance
      final testInstance = SimplePropertyTest(name: 'Test Name');

      // Test round-trip serialization/deserialization
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);

      final deserialized = mapper.decodeObject<SimplePropertyTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(testInstance.name),
          reason: 'Normal properties should round-trip correctly');
    });

    test('OptionalPropertyTest - nullable property behavior', () {
      // Test with non-null value (test this first to avoid empty graph issues)
      final testInstanceValue = OptionalPropertyTest(name: 'Test Name');
      final serializedValue = mapper.encodeObject(testInstanceValue);
      expect(serializedValue, isNotNull);

      final deserializedValue =
          mapper.decodeObject<OptionalPropertyTest>(serializedValue);
      expect(deserializedValue, isNotNull);
      expect(deserializedValue.name, equals('Test Name'),
          reason: 'Non-null optional values should round-trip correctly');

      // Test with null value - this may result in empty serialization
      final testInstanceNull = OptionalPropertyTest(name: null);
      final serializedNull = mapper.encodeObject(testInstanceNull);
      expect(serializedNull, isNotNull);

      final deserializedNull =
          mapper.decodeObject<OptionalPropertyTest>(serializedNull);
      expect(deserializedNull, isNotNull);
      expect(deserializedNull.name, isNull,
          reason: 'Null values should round-trip correctly');
    });

    test('DefaultValueTest - custom value behavior', () {
      // Create instance with explicit value
      final testInstance = DefaultValueTest(isbn: 'custom-isbn');

      // Test round-trip
      final serialized = mapper.encodeObject(testInstance);
      final deserialized = mapper.decodeObject<DefaultValueTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals('custom-isbn'),
          reason: 'Custom values should override defaults');
      expect(serialized, contains('schema:isbn "custom-isbn" .'));
    });

    test('DefaultValueTest - default value behavior', () {
      final turtle = '''
@prefix books: <http://example.org/books/> .
@prefix schema: <https://schema.org/> .

books:singleton a schema:Book .
''';
      final deserialized = mapper.decodeObject<DefaultValueTest>(turtle);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals('default-isbn'),
          reason: 'Custom values should override defaults');
      final serialized = mapper.encodeObject(deserialized);
      expect(serialized, isNot(contains('schema:isbn')),
          reason: 'Default values should not be serialized');
    });

    test('IncludeDefaultsTest - includeDefaultsInSerialization behavior', () {
      // Create instance with default value
      final testInstance =
          IncludeDefaultsTest(rating: 5); // 5 is the default value

      // Test round-trip to verify behavior
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);
      expect(serialized, contains('schema:numberOfPages 5'),
          reason:
              'Default values should be included when includeDefaultsInSerialization: true');
      final deserialized = mapper.decodeObject<IncludeDefaultsTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.rating, equals(5),
          reason:
              'Default values should be included when includeDefaultsInSerialization: true');
    });

    test('DeserializationOnlyPropertyTest - serialization comparison', () {
      // This test demonstrates the core functionality: properties with include: false
      // should not affect the serialized output

      final instanceA = DeserializationOnlyPropertyTest(name: 'Different');
      final instanceB = DeserializationOnlyPropertyTest(name: 'Names');
      final instanceC = DeserializationOnlyPropertyTest(name: 'Here');

      final serializedA = mapper.encodeObject(instanceA);
      final serializedB = mapper.encodeObject(instanceB);
      final serializedC = mapper.encodeObject(instanceC);

      // All serialized forms should be identical because name property is excluded
      expect(serializedA, equals(serializedB),
          reason:
              'Different values for include: false properties should produce identical serialization');
      expect(serializedB, equals(serializedC),
          reason:
              'Different values for include: false properties should produce identical serialization');
      expect(serializedA, equals(serializedC),
          reason:
              'Different values for include: false properties should produce identical serialization');
    });

    test('Comparison with normal property - verify difference', () {
      // Compare behavior between include: false and normal properties

      // DeserializationOnlyPropertyTest has include: false
      final deserOnlyA = DeserializationOnlyPropertyTest(name: 'NameA');
      final deserOnlyB = DeserializationOnlyPropertyTest(name: 'NameB');

      // SimplePropertyTest has normal behavior (include: true by default)
      final simpleA = SimplePropertyTest(name: 'NameA');
      final simpleB = SimplePropertyTest(name: 'NameB');

      final deserOnlySerializedA = mapper.encodeObject(deserOnlyA);
      final deserOnlySerializedB = mapper.encodeObject(deserOnlyB);
      final simpleSerializedA = mapper.encodeObject(simpleA);
      final simpleSerializedB = mapper.encodeObject(simpleB);

      // DeserializationOnly instances with different names should serialize identically
      expect(deserOnlySerializedA, equals(deserOnlySerializedB),
          reason:
              'Properties with include: false should not affect serialization');

      // Simple instances with different names should serialize differently
      expect(simpleSerializedA, isNot(equals(simpleSerializedB)),
          reason: 'Normal properties should affect serialization');
    });

    test('IriMappingTest - IRI template mapping behavior', () {
      // Test basic functionality with different author IDs
      final authorId1 = 'john-doe';
      final authorId2 = 'jane-smith';
      final authorId3 = 'special-chars-author';

      final testInstance1 = IriMappingTest(authorId: authorId1);
      final testInstance2 = IriMappingTest(authorId: authorId2);
      final testInstance3 = IriMappingTest(authorId: authorId3);

      // Test serialization - should use IRI template 'http://example.org/authors/{authorId}'
      final serialized1 = mapper.encodeObject(testInstance1);
      final serialized2 = mapper.encodeObject(testInstance2);
      final serialized3 = mapper.encodeObject(testInstance3);

      expect(serialized1, isNotNull);
      expect(serialized2, isNotNull);
      expect(serialized3, isNotNull);

      // Verify that different authorIds produce different serialized forms
      expect(serialized1, isNot(equals(serialized2)),
          reason:
              'Different authorIds should produce different serialized forms');
      expect(serialized2, isNot(equals(serialized3)),
          reason:
              'Different authorIds should produce different serialized forms');

      // Check that the IRI template is used correctly - RDF output uses prefixes
      // The prefix declaration should be: @prefix authors: <http://example.org/authors/> .
      expect(serialized1,
          contains('@prefix authors: <http://example.org/authors/>'),
          reason:
              'Serialized data should contain the prefix for the IRI namespace');
      expect(serialized1, contains('authors:john-doe'),
          reason:
              'Serialized data should contain the author IRI using prefix notation');
      expect(serialized2, contains('authors:jane-smith'),
          reason:
              'Serialized data should contain the author IRI using prefix notation');
      expect(serialized3, contains('authors:special-chars-author'),
          reason:
              'Serialized data should contain the author IRI using prefix notation');

      // Test round-trip serialization/deserialization
      final deserialized1 = mapper.decodeObject<IriMappingTest>(serialized1);
      final deserialized2 = mapper.decodeObject<IriMappingTest>(serialized2);
      final deserialized3 = mapper.decodeObject<IriMappingTest>(serialized3);

      expect(deserialized1, isNotNull);
      expect(deserialized2, isNotNull);
      expect(deserialized3, isNotNull);

      // Verify that the authorId values are preserved through round-trip
      expect(deserialized1.authorId, equals(authorId1),
          reason: 'IRI mapping should preserve authorId through round-trip');
      expect(deserialized2.authorId, equals(authorId2),
          reason: 'IRI mapping should preserve authorId through round-trip');
      expect(deserialized3.authorId, equals(authorId3),
          reason: 'IRI mapping should preserve authorId through round-trip');
    });

    test('IriMappingTest - edge cases and special characters', () {
      // Test edge cases with valid IRI characters
      final authorIdWithDashes = 'author-with-dashes';
      final authorIdWithUnderscores = 'author_name';
      final authorIdLong = 'a-very-long-author-name-with-many-characters';

      final testInstanceDashes = IriMappingTest(authorId: authorIdWithDashes);
      final testInstanceUnderscores =
          IriMappingTest(authorId: authorIdWithUnderscores);
      final testInstanceLong = IriMappingTest(authorId: authorIdLong);

      // Test serialization for edge cases
      final serializedDashes = mapper.encodeObject(testInstanceDashes);
      final serializedUnderscores =
          mapper.encodeObject(testInstanceUnderscores);
      final serializedLong = mapper.encodeObject(testInstanceLong);

      expect(serializedDashes, isNotNull);
      expect(serializedUnderscores, isNotNull);
      expect(serializedLong, isNotNull);

      // Verify that different authorIds produce different serialized forms
      expect(serializedDashes, isNot(equals(serializedUnderscores)),
          reason:
              'Different authorIds should produce different serialized forms');
      expect(serializedUnderscores, isNot(equals(serializedLong)),
          reason:
              'Different authorIds should produce different serialized forms');

      // Check for proper IRI generation - all should use valid prefix notation
      expect(serializedDashes, contains('authors:author-with-dashes'),
          reason: 'Should contain author ID with dashes in prefixed form');
      expect(serializedUnderscores, contains('authors:author_name'),
          reason: 'Should contain author ID with underscores in prefixed form');
      expect(serializedLong,
          contains('authors:a-very-long-author-name-with-many-characters'),
          reason: 'Should contain long author ID in prefixed form');

      // Test round-trip for edge cases
      final deserializedDashes =
          mapper.decodeObject<IriMappingTest>(serializedDashes);
      final deserializedUnderscores =
          mapper.decodeObject<IriMappingTest>(serializedUnderscores);
      final deserializedLong =
          mapper.decodeObject<IriMappingTest>(serializedLong);

      expect(deserializedDashes, isNotNull);
      expect(deserializedUnderscores, isNotNull);
      expect(deserializedLong, isNotNull);

      // Verify values are preserved
      expect(deserializedDashes.authorId, equals(authorIdWithDashes),
          reason:
              'Author ID with dashes should be preserved through round-trip');
      expect(deserializedUnderscores.authorId, equals(authorIdWithUnderscores),
          reason:
              'Author ID with underscores should be preserved through round-trip');
      expect(deserializedLong.authorId, equals(authorIdLong),
          reason: 'Long author ID should be preserved through round-trip');
    });

    test('IriMappingTest - empty author ID edge case', () {
      // Test specifically for empty author ID case which has different serialization behavior
      final authorIdEmpty = '';
      final testInstanceEmpty = IriMappingTest(authorId: authorIdEmpty);

      final serializedEmpty = mapper.encodeObject(testInstanceEmpty);
      expect(serializedEmpty, isNotNull);

      // Empty authorId creates a direct IRI reference without prefix
      expect(serializedEmpty, contains('<http://example.org/authors/>'),
          reason: 'Empty author ID should create direct IRI reference');

      // Test round-trip for empty case
      final deserializedEmpty =
          mapper.decodeObject<IriMappingTest>(serializedEmpty);
      expect(deserializedEmpty, isNotNull);
      expect(deserializedEmpty.authorId, equals(authorIdEmpty),
          reason: 'Empty author ID should be preserved through round-trip');
    });

    test(
        'IriMappingWithBaseUriTest - IRI template mapping with base URI expansion',
        () {
      // Test basic functionality with different author IDs and base URIs
      final authorId1 = 'john-doe';
      final authorId2 = 'jane-smith';
      final authorId3 = 'special-chars-author';

      final baseUri1 = 'https://example.org';
      final baseUri2 = 'https://company.com';
      final baseUri3 = 'http://test.domain.net';

      // Create mappers with different base URI providers
      final mapper1 = defaultInitTestRdfMapper(baseUriProvider: () => baseUri1);
      final mapper2 = defaultInitTestRdfMapper(baseUriProvider: () => baseUri2);
      final mapper3 = defaultInitTestRdfMapper(baseUriProvider: () => baseUri3);

      final testInstance1 = IriMappingWithBaseUriTest(authorId: authorId1);
      final testInstance2 = IriMappingWithBaseUriTest(authorId: authorId2);
      final testInstance3 = IriMappingWithBaseUriTest(authorId: authorId3);

      // Test serialization with different base URIs
      final serialized1 = mapper1.encodeObject(testInstance1);
      final serialized2 = mapper2.encodeObject(testInstance2);
      final serialized3 = mapper3.encodeObject(testInstance3);

      expect(serialized1, isNotNull);
      expect(serialized2, isNotNull);
      expect(serialized3, isNotNull);

      // Verify that different combinations produce different serialized forms
      expect(serialized1, isNot(equals(serialized2)),
          reason:
              'Different base URIs should produce different serialized forms');
      expect(serialized2, isNot(equals(serialized3)),
          reason:
              'Different base URIs should produce different serialized forms');

      // Check that the correct base URI is used in the generated IRIs
      // For baseUri1 + authorId1: https://example.org/authors/john-doe
      expect(serialized1, contains('https://example.org/authors/'),
          reason: 'Serialized data should contain the correct base URI');
      expect(serialized1, contains('john-doe'),
          reason: 'Serialized data should contain the author ID');

      // For baseUri2 + authorId2: https://company.com/authors/jane-smith
      expect(serialized2, contains('https://company.com/authors/'),
          reason: 'Serialized data should contain the correct base URI');
      expect(serialized2, contains('jane-smith'),
          reason: 'Serialized data should contain the author ID');

      // For baseUri3 + authorId3: http://test.domain.net/authors/special-chars-author
      expect(serialized3, contains('http://test.domain.net/authors/'),
          reason: 'Serialized data should contain the correct base URI');
      expect(serialized3, contains('special-chars-author'),
          reason: 'Serialized data should contain the author ID');

      // Test round-trip serialization/deserialization
      final deserialized1 =
          mapper1.decodeObject<IriMappingWithBaseUriTest>(serialized1);
      final deserialized2 =
          mapper2.decodeObject<IriMappingWithBaseUriTest>(serialized2);
      final deserialized3 =
          mapper3.decodeObject<IriMappingWithBaseUriTest>(serialized3);

      expect(deserialized1, isNotNull);
      expect(deserialized2, isNotNull);
      expect(deserialized3, isNotNull);

      // Verify that the authorId values are preserved through round-trip
      expect(deserialized1.authorId, equals(authorId1),
          reason:
              'Base URI IRI mapping should preserve authorId through round-trip');
      expect(deserialized2.authorId, equals(authorId2),
          reason:
              'Base URI IRI mapping should preserve authorId through round-trip');
      expect(deserialized3.authorId, equals(authorId3),
          reason:
              'Base URI IRI mapping should preserve authorId through round-trip');
    });

    test(
        'IriMappingWithBaseUriTest - cross-baseUri serialization compatibility',
        () {
      // Test that data serialized with one base URI can be deserialized with a different base URI
      // This tests the robustness of the IRI template parsing
      final authorId = 'test-author';
      final baseUri1 = 'https://domain1.com';
      final baseUri2 = 'https://domain2.org';

      final mapper1 = defaultInitTestRdfMapper(baseUriProvider: () => baseUri1);
      final mapper2 = defaultInitTestRdfMapper(baseUriProvider: () => baseUri2);

      final testInstance = IriMappingWithBaseUriTest(authorId: authorId);

      // Serialize with mapper1 (baseUri1)
      final serialized = mapper1.encodeObject(testInstance);
      expect(serialized, isNotNull);
      expect(serialized, contains('https://domain1.com/authors/'),
          reason: 'Should serialize with the first base URI');

      // Deserialize with mapper2 (baseUri2) - should still extract the authorId correctly
      final deserialized =
          mapper2.decodeObject<IriMappingWithBaseUriTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.authorId, equals(authorId),
          reason:
              'AuthorId should be extracted correctly regardless of deserialization base URI');
    });

    test(
        'IriMappingWithBaseUriTest - edge cases with different base URI formats',
        () {
      // Test various base URI formats to ensure template expansion works correctly
      final authorId = 'test-author';

      final testCases = [
        'https://example.com',
        'http://test.org',
        'https://api.service.com/v1',
        'http://localhost:8080',
        'https://subdomain.example.org/path',
      ];

      for (final baseUri in testCases) {
        final mapper = defaultInitTestRdfMapper(baseUriProvider: () => baseUri);
        final testInstance = IriMappingWithBaseUriTest(authorId: authorId);

        // Test serialization
        final serialized = mapper.encodeObject(testInstance);
        expect(serialized, isNotNull,
            reason: 'Serialization should work with base URI: $baseUri');

        // Verify the correct IRI is generated
        final expectedIriPrefix = '$baseUri/authors/';
        expect(serialized, contains(expectedIriPrefix),
            reason:
                'Should contain the correct IRI prefix for base URI: $baseUri');

        // Test round-trip
        final deserialized =
            mapper.decodeObject<IriMappingWithBaseUriTest>(serialized);
        expect(deserialized, isNotNull,
            reason: 'Deserialization should work with base URI: $baseUri');
        expect(deserialized.authorId, equals(authorId),
            reason: 'AuthorId should be preserved with base URI: $baseUri');
      }
    });
  });
}
