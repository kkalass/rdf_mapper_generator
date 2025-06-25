import 'package:rdf_core/rdf_core.dart';
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
      expect(serialized1, isNot(equals(serialized3)),
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

    test(
        'IriMappingFullIriTest - full IRI mapping behavior with custom default vs IriFullMapper override',
        () {
      // Create a custom string IRI mapper that should be overridden
      final customStringIriMapper = CustomTestStringIriMapper();

      // Create a mapper with custom string IRI mapper
      final mapperWithCustom = defaultInitTestRdfMapper(
        iriMapper: customStringIriMapper,
      );

      // First, test that our custom string IRI mapper works for normal string mapping
      // We can test this indirectly through IriMappingNamedMapperTest which uses a named mapper
      final namedMapperTest =
          IriMappingNamedMapperTest(authorId: 'test-author');

      final namedMapperSerialized = mapperWithCustom
          .encodeObject(namedMapperTest, contentType: 'application/n-triples');
      expect(namedMapperSerialized,
          contains('<http://example.org/custom-prefix/test-author>'),
          reason: 'Named mapper should use the custom string IRI mapper');

      // Now test IriMappingFullIriTest (explicit template syntax)
      final fullIriTestExplicit = IriMappingFullIriTest(
        authorIri: 'https://example.org/persons/john-doe',
      );

      // Test serialization - should use IriFullMapper, not the custom mapper
      final serializedExplicit = mapperWithCustom.encodeObject(
          fullIriTestExplicit,
          contentType: 'application/n-triples');
      expect(serializedExplicit, isNotNull);

      // The full IRI should be used directly, not processed by custom mapper
      expect(serializedExplicit,
          contains('<https://example.org/persons/john-doe>'),
          reason: 'Full IRI mapping should use the complete IRI as-is');
      expect(serializedExplicit,
          isNot(contains('<http://example.org/custom-prefix/')),
          reason:
              'Full IRI mapping should not use the custom string IRI mapper');

      // Test round-trip serialization/deserialization
      final deserializedExplicit = mapperWithCustom
          .decodeObject<IriMappingFullIriTest>(serializedExplicit);
      expect(deserializedExplicit, isNotNull);
      expect(deserializedExplicit.authorIri,
          equals('https://example.org/persons/john-doe'),
          reason: 'Full IRI should be preserved through round-trip');

      // Test IriMappingFullIriSimpleTest (simple syntax)
      final fullIriTestSimple = IriMappingFullIriSimpleTest(
        authorIri: 'https://example.org/authors/jane-smith',
      );

      final serializedSimple = mapperWithCustom.encodeObject(fullIriTestSimple,
          contentType: 'application/n-triples');
      expect(serializedSimple, isNotNull);

      // The full IRI should be used directly here as well
      expect(serializedSimple,
          contains('<https://example.org/authors/jane-smith>'),
          reason: 'Simple full IRI mapping should use the complete IRI as-is');
      expect(serializedSimple,
          isNot(contains('<http://example.org/custom-prefix/')),
          reason:
              'Simple full IRI mapping should not use the custom string IRI mapper');

      // Test round-trip for simple syntax
      final deserializedSimple = mapperWithCustom
          .decodeObject<IriMappingFullIriSimpleTest>(serializedSimple);
      expect(deserializedSimple, isNotNull);
      expect(deserializedSimple.authorIri,
          equals('https://example.org/authors/jane-smith'),
          reason: 'Simple full IRI should be preserved through round-trip');
    });

    test('IriMappingFullIriTest - edge cases and various IRI formats', () {
      // Test various IRI formats to ensure proper handling
      final testCases = [
        'https://example.com/simple',
        'http://example.org/path/to/resource',
        'https://subdomain.example.org/complex/path?param=value',
        'urn:isbn:1234567890',
        'mailto:test@example.com',
        'file:///local/path/resource',
        'https://example.org/unicode/café',
        'https://example.org/special-chars_123',
      ];

      for (final testIri in testCases) {
        // Test explicit template syntax
        final explicitTest = IriMappingFullIriTest(authorIri: testIri);
        final explicitSerialized = mapper.encodeObject(explicitTest,
            contentType: 'application/n-triples');
        expect(explicitSerialized, isNotNull,
            reason: 'Serialization should work for IRI: $testIri');
        expect(explicitSerialized, contains('<$testIri>'),
            reason:
                'Serialized form should contain the original IRI: $testIri');

        final explicitDeserialized =
            mapper.decodeObject<IriMappingFullIriTest>(explicitSerialized);
        expect(explicitDeserialized.authorIri, equals(testIri),
            reason: 'Round-trip should preserve IRI: $testIri');

        // Test simple syntax
        final simpleTest = IriMappingFullIriSimpleTest(authorIri: testIri);
        final simpleSerialized = mapper.encodeObject(simpleTest,
            contentType: 'application/n-triples');
        expect(simpleSerialized, isNotNull,
            reason:
                'Simple syntax serialization should work for IRI: $testIri');
        expect(simpleSerialized, contains('<$testIri>'),
            reason: 'Simple syntax should contain the original IRI: $testIri');

        final simpleDeserialized =
            mapper.decodeObject<IriMappingFullIriSimpleTest>(simpleSerialized);
        expect(simpleDeserialized.authorIri, equals(testIri),
            reason: 'Simple syntax round-trip should preserve IRI: $testIri');
      }
    });

    test(
        'IriMappingFullIriTest vs other IRI mapping strategies - behavior comparison',
        () {
      // Test to demonstrate the difference between full IRI mapping and other strategies

      // 1. IriMappingTest (template-based mapping)
      final templateTest = IriMappingTest(authorId: 'john-doe');
      final templateSerialized = mapper.encodeObject(templateTest,
          contentType: 'application/n-triples');
      expect(
          templateSerialized, contains('<http://example.org/authors/john-doe>'),
          reason: 'Template mapping should use the full expanded template IRI');

      // 2. IriMappingFullIriTest (full IRI mapping with explicit template)
      final fullExplicitTest = IriMappingFullIriTest(
        authorIri: 'https://other.domain.org/persons/john-doe',
      );
      final fullExplicitSerialized = mapper.encodeObject(fullExplicitTest,
          contentType: 'application/n-triples');
      expect(fullExplicitSerialized,
          contains('<https://other.domain.org/persons/john-doe>'),
          reason: 'Full IRI mapping should preserve the complete IRI');

      // 3. IriMappingFullIriSimpleTest (full IRI mapping with simple syntax)
      final fullSimpleTest = IriMappingFullIriSimpleTest(
        authorIri: 'https://another.domain.com/users/john-doe',
      );
      final fullSimpleSerialized = mapper.encodeObject(fullSimpleTest,
          contentType: 'application/n-triples');
      expect(fullSimpleSerialized,
          contains('<https://another.domain.com/users/john-doe>'),
          reason: 'Simple full IRI mapping should preserve the complete IRI');

      // Verify they produce different serialized forms
      expect(templateSerialized, isNot(equals(fullExplicitSerialized)),
          reason:
              'Template and full IRI mapping should produce different results');
      expect(templateSerialized, isNot(equals(fullSimpleSerialized)),
          reason:
              'Template and simple full IRI mapping should produce different results');
      expect(fullExplicitSerialized, isNot(equals(fullSimpleSerialized)),
          reason: 'Different domains should produce different results');
    });

    test('IriMappingFullIriTest - cross-mapper compatibility', () {
      // Test that data serialized with one mapper configuration can be
      // deserialized with another (within reason)

      final testIri = 'https://stable.example.org/author/test-person';

      // Create instances with both syntaxes using the same IRI
      final explicitTest = IriMappingFullIriTest(authorIri: testIri);
      final simpleTest = IriMappingFullIriSimpleTest(authorIri: testIri);

      // Serialize with default mapper
      final explicitSerialized = mapper.encodeObject(explicitTest,
          contentType: 'application/n-triples');
      final simpleSerialized =
          mapper.encodeObject(simpleTest, contentType: 'application/n-triples');

      // Both should contain the same IRI reference
      expect(explicitSerialized, contains('<$testIri>'));
      expect(simpleSerialized, contains('<$testIri>'));

      // Cross-deserialization should work (both use the same IRI structure)
      final explicitFromSimple =
          mapper.decodeObject<IriMappingFullIriTest>(simpleSerialized);
      final simpleFromExplicit =
          mapper.decodeObject<IriMappingFullIriSimpleTest>(explicitSerialized);

      expect(explicitFromSimple.authorIri, equals(testIri),
          reason:
              'Should be able to deserialize simple syntax as explicit template');
      expect(simpleFromExplicit.authorIri, equals(testIri),
          reason:
              'Should be able to deserialize explicit template as simple syntax');
    });

    test(
        'SimpleCustomPropertyTest - global resource with custom IRI and IRI part',
        () {
      // Create instance with IRI part that will be used in global resource IRI
      final testInstance = SimpleCustomPropertyTest(name: 'test-book');

      // Test serialization - should create global resource with IRI strategy
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);

      // Should contain the expected IRI pattern with the name as IRI part
      expect(serialized, contains('books:test-book'),
          reason:
              'Should use IRI strategy with name as IRI part in prefixed form');

      // Should contain the custom property predicate
      expect(serialized, contains('<http://example.org/types/Book/name>'),
          reason: 'Should use custom property predicate IRI');

      // Test round-trip serialization/deserialization
      final deserialized =
          mapper.decodeObject<SimpleCustomPropertyTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(testInstance.name),
          reason: 'Name should be preserved through round-trip');
    });

    test('LanguageTagTest - literal mapping with language tag', () {
      // Create test instance with English description
      final testInstance = LanguageTagTest(description: 'A fascinating book');

      // Test round-trip serialization/deserialization
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);

      // Verify that the serialized RDF contains the language tag
      expect(serialized, contains('@en'),
          reason: 'Language tag should be preserved in serialization');
      expect(serialized, contains('A fascinating book'),
          reason: 'Description value should be in serialization');

      final deserialized = mapper.decodeObject<LanguageTagTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.description, equals(testInstance.description),
          reason: 'Description should round-trip correctly with language tag');
    });

    test('DatatypeTest - literal mapping with custom datatype', () {
      // Create test instance with integer that will be serialized as string
      const testCount = 42;
      final testInstance = DatatypeTest(count: testCount);

      // Test round-trip serialization/deserialization
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);

      // Verify that the integer value is serialized as a string literal
      // Note: xsd:string is the default datatype for string literals in RDF, so it's often omitted
      expect(serialized, contains('"$testCount"'),
          reason: 'Integer value should be serialized as string literal due to withType(Xsd.string)');

      final deserialized = mapper.decodeObject<DatatypeTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.count, equals(testInstance.count),
          reason: 'Integer should round-trip correctly even when serialized with string datatype');
    });

    test('IriMappingWithProviderTest - IRI template mapping with provider', () {
      // Create test instances
      const authorId1 = 'author-123';
      const authorId2 = 'author-456';
      final testInstance1 = IriMappingWithProviderTest(authorId: authorId1);
      final testInstance2 = IriMappingWithProviderTest(authorId: authorId2);

      // Test serialization
      final serialized1 = mapper.encodeObject(testInstance1);
      final serialized2 = mapper.encodeObject(testInstance2);
      expect(serialized1, isNotNull);
      expect(serialized2, isNotNull);

      // Verify the generated IRIs use the provider value 'fiction' as namespace prefix
      expect(serialized1, contains('fiction:$authorId1'),
          reason: 'IRI should be generated using provider value as namespace');
      expect(serialized2, contains('fiction:$authorId2'),
          reason: 'IRI should be generated using provider value as namespace');
      
      // Verify the namespace is defined
      expect(serialized1, contains('@prefix fiction: <http://example.org/fiction/>'),
          reason: 'Fiction namespace should be defined');
      expect(serialized2, contains('@prefix fiction: <http://example.org/fiction/>'),
          reason: 'Fiction namespace should be defined');

      // Test deserialization
      final deserialized1 = mapper.decodeObject<IriMappingWithProviderTest>(serialized1);
      final deserialized2 = mapper.decodeObject<IriMappingWithProviderTest>(serialized2);
      
      expect(deserialized1.authorId, equals(authorId1));
      expect(deserialized2.authorId, equals(authorId2));
    });

    test('IriMappingWithBaseUriProviderTest - IRI template mapping with base URI provider', () {
      // Create test instances
      const authorId1 = 'author-789';
      const authorId2 = 'author-012';
      final testInstance1 = IriMappingWithBaseUriProviderTest(authorId: authorId1);
      final testInstance2 = IriMappingWithBaseUriProviderTest(authorId: authorId2);

      // Test serialization
      final serialized1 = mapper.encodeObject(testInstance1);
      final serialized2 = mapper.encodeObject(testInstance2);
      expect(serialized1, isNotNull);
      expect(serialized2, isNotNull);

      // Verify the generated IRIs use the base URI provider value as namespace prefix
      expect(serialized1, contains('foo:$authorId1'),
          reason: 'IRI should be generated using base URI provider value as namespace');
      expect(serialized2, contains('foo:$authorId2'),
          reason: 'IRI should be generated using base URI provider value as namespace');
      
      // Verify the namespace is defined
      expect(serialized1, contains('@prefix foo: <http://foo.example.org/>'),
          reason: 'Foo namespace should be defined');
      expect(serialized2, contains('@prefix foo: <http://foo.example.org/>'),
          reason: 'Foo namespace should be defined');

      // Test deserialization
      final deserialized1 = mapper.decodeObject<IriMappingWithBaseUriProviderTest>(serialized1);
      final deserialized2 = mapper.decodeObject<IriMappingWithBaseUriProviderTest>(serialized2);
      
      expect(deserialized1.authorId, equals(authorId1));
      expect(deserialized2.authorId, equals(authorId2));
    });

    test('IriMappingWithProviderPropertyTest - IRI template mapping with property provider', () {
      // Create test instances with different genres
      const authorId1 = 'author-345';
      const authorId2 = 'author-678';
      const genre1 = 'science-fiction';
      const genre2 = 'fantasy';
      
      final testInstance1 = IriMappingWithProviderPropertyTest(
          authorId: authorId1, genre: genre1);
      final testInstance2 = IriMappingWithProviderPropertyTest(
          authorId: authorId2, genre: genre2);

      // Test serialization
      final serialized1 = mapper.encodeObject(testInstance1);
      final serialized2 = mapper.encodeObject(testInstance2);
      expect(serialized1, isNotNull);
      expect(serialized2, isNotNull);

      // Verify the generated IRIs use the genre property as provider for namespace prefix
      expect(serialized1, contains('sf:$authorId1'),
          reason: 'IRI should be generated using genre property as provider namespace');
      expect(serialized2, contains('fantasy:$authorId2'),
          reason: 'IRI should be generated using genre property as provider namespace');
      
      // Verify the namespaces are defined
      expect(serialized1, contains('@prefix sf: <http://example.org/science-fiction/>'),
          reason: 'Science-fiction namespace should be defined');
      expect(serialized2, contains('@prefix fantasy: <http://example.org/fantasy/>'),
          reason: 'Fantasy namespace should be defined');

      // Verify genre is also serialized as a separate property
      expect(serialized1, contains(genre1),
          reason: 'Genre should be serialized as property');
      expect(serialized2, contains(genre2),
          reason: 'Genre should be serialized as property');

      // Test deserialization
      final deserialized1 = mapper.decodeObject<IriMappingWithProviderPropertyTest>(serialized1);
      final deserialized2 = mapper.decodeObject<IriMappingWithProviderPropertyTest>(serialized2);
      
      expect(deserialized1.authorId, equals(authorId1));
      expect(deserialized1.genre, equals(genre1));
      expect(deserialized2.authorId, equals(authorId2));
      expect(deserialized2.genre, equals(genre2));
    });
  });
}

/// Custom test IRI mapper for String values that adds a prefix
/// This is used to test that full IRI mapping overrides the default string mapper
class CustomTestStringIriMapper implements IriTermMapper<String> {
  const CustomTestStringIriMapper();

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    final iri = term.iri;
    if (iri.startsWith('http://example.org/custom-prefix/')) {
      return iri.substring('http://example.org/custom-prefix/'.length);
    }
    return iri; // fallback for other IRIs
  }

  @override
  IriTerm toRdfTerm(String value, SerializationContext context) {
    // Add custom prefix to demonstrate this mapper is being used
    if (value.startsWith('http://') || value.startsWith('https://')) {
      // Don't modify full IRIs - this tests whether our mapper is bypassed
      return IriTerm(value);
    }
    return IriTerm('http://example.org/custom-prefix/$value');
  }
}
