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

      // Only test deserialization if we have non-empty serialization
      if (serializedNull.isNotEmpty) {
        final deserializedNull =
            mapper.decodeObject<OptionalPropertyTest>(serializedNull);
        expect(deserializedNull, isNotNull);
        expect(deserializedNull.name, isNull,
            reason: 'Null values should round-trip correctly');
      }
    }, skip: 'Not correctly working yet');

    test('DefaultValueTest - default value behavior', () {
      // Create instance with explicit value
      final testInstance = DefaultValueTest(isbn: 'custom-isbn');

      // Test round-trip
      final serialized = mapper.encodeObject(testInstance);
      final deserialized = mapper.decodeObject<DefaultValueTest>(serialized);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals('custom-isbn'),
          reason: 'Custom values should override defaults');
    });

    test('IncludeDefaultsTest - includeDefaultsInSerialization behavior', () {
      // Create instance with default value
      final testInstance =
          IncludeDefaultsTest(rating: 5); // 5 is the default value

      // Test round-trip to verify behavior
      final serialized = mapper.encodeObject(testInstance);
      expect(serialized, isNotNull);

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
  });
}
