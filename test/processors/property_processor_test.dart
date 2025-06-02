import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late final LibraryElement2 libraryElement;

  setUpAll(() async {
    libraryElement =
        await analyzeTestFile('property_processor_test_models.dart');
  });

  group('PropertyProcessor', () {
    test('should return null for field without RdfProperty annotation', () {
      // Arrange
      final field =
          libraryElement.getClass2('NoAnnotationTest')!.getField2('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in NoAnnotationTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNull);
    });

    test('should process simple property', () {
      // Arrange
      final field =
          libraryElement.getClass2('SimplePropertyTest')!.getField2('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in SimplePropertyTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'name');
      expect(result.annotation.predicate, equals(SchemaBook.name));
      expect(result.annotation.include, isTrue);
      expect(result.annotation.includeDefaultsInSerialization, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);
    });

    test('should process property that is only deserialized, not serialized',
        () {
      // Arrange
      final field = libraryElement
          .getClass2('DeserializationOnlyPropertyTest')!
          .getField2('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in DeserializationOnlyPropertyTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.annotation.include, isFalse);
    });

    test('should process optional property', () {
      // Arrange
      final field =
          libraryElement.getClass2('OptionalPropertyTest')!.getField2('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in OptionalPropertyTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isRequired, isFalse);
    });

    test('should process property with default value', () {
      // Arrange
      final field =
          libraryElement.getClass2('DefaultValueTest')!.getField2('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in DefaultValueTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final defaultValue = annotation.defaultValue!;
      expect(defaultValue, isNotNull);
      expect(defaultValue.toStringValue(), 'default-isbn');
      expect(annotation.includeDefaultsInSerialization, isFalse);
    });

    test('should process property with includeDefaultsInSerialization', () {
      // Arrange
      final field =
          libraryElement.getClass2('IncludeDefaultsTest')!.getField2('rating');
      expect(field, isNotNull,
          reason: 'Field "rating" not found in IncludeDefaultsTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.includeDefaultsInSerialization, isTrue);
      final defaultValue = annotation.defaultValue!;
      expect(defaultValue, isNotNull);
      expect(defaultValue.toIntValue(), 5);
    });

    test('should process property with IRI mapping', () {
      // Arrange
      final field =
          libraryElement.getClass2('IriMappingTest')!.getField2('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.iri, isNotNull);
      expect(
        annotation.iri!.template,
        'http://example.org/authors/{authorId}',
      );
      expect(annotation.iri!.mapper, isNull);
    });

    test('should process property with IRI mapping (named)', () {
      // Arrange
      final field = libraryElement
          .getClass2('IriMappingNamedMapperTest')!
          .getField2('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingNamedMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, 'iriMapper');
      expect(mapper.instance, isNull);
      expect(mapper.type, isNull);
    });

    test('should process property with IRI mapping (type)', () {
      // Arrange
      final field = libraryElement
          .getClass2('IriMappingMapperTest')!
          .getField2('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, isNull);
      expect(mapper.instance, isNull);
      expect(mapper.type, isNotNull);

      expect(mapper.type!.type, isNotNull);
      expect(mapper.type!.type!.getDisplayString(), 'Type');
      expect(mapper.type!.toTypeValue(), isNotNull);
      expect(mapper.type!.toTypeValue()!.getDisplayString(), 'IriMapperImpl');
    });

    test('should process property with IRI mapping (instance)', () {
      // Arrange
      final field = libraryElement
          .getClass2('IriMappingMapperInstanceTest')!
          .getField2('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingMapperInstanceTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, isNull);
      expect(mapper.instance, isNotNull);
      expect(mapper.type, isNull);
      expect(mapper.instance!.type, isNotNull);
      expect(mapper.instance!.type!.getDisplayString(), 'IriMapperImpl');
      expect(mapper.instance!.toString(), 'IriMapperImpl ()');
      expect(mapper.instance!.hasKnownValue, isTrue);
    });

    test('should process property with local resource mapping', () {
      // Arrange
      final field = libraryElement
          .getClass2('LocalResourceMappingTest')!
          .getField2('author');
      expect(field, isNotNull,
          reason: 'Field "author" not found in LocalResourceMappingTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.name, 'testLocalMapper');
    });

    test('should process property with global resource mapping', () {
      // Arrange
      final field = libraryElement
          .getClass2('GlobalResourceMappingTest')!
          .getField2('publisher');
      expect(field, isNotNull,
          reason: 'Field "publisher" not found in GlobalResourceMappingTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.globalResource!.mapper, isNotNull);
      expect(annotation.globalResource!.mapper!.name, 'testGlobalMapper');
    });

    test('should process property with literal mapping', () {
      // Arrange
      final field =
          libraryElement.getClass2('LiteralMappingTest')!.getField2('price');
      expect(field, isNotNull,
          reason: 'Field "price" not found in LiteralMappingTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, 'testLiteralMapper');
    });

    test('should process collection properties (none)', () {
      // Test collection
      final field =
          libraryElement.getClass2('CollectionNoneTest')!.getField2('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionNoneTest');

      final result = PropertyProcessor.processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection, RdfCollectionType.none);
    });

    test('should process collection properties (auto)', () {
      // Test collection
      final field =
          libraryElement.getClass2('CollectionAutoTest')!.getField2('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionAutoTest');

      final result = PropertyProcessor.processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection, RdfCollectionType.auto);
    });

    test('should process collection properties (default)', () {
      // Test collection
      final field =
          libraryElement.getClass2('CollectionTest')!.getField2('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionTest');

      final result = PropertyProcessor.processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection, RdfCollectionType.auto);
    });

    test('should process enum type property', () {
      // Arrange
      final field =
          libraryElement.getClass2('EnumTypeTest')!.getField2('format');
      expect(field, isNotNull,
          reason: 'Field "format" not found in EnumTypeTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'BookFormatType');
      expect(result.annotation.predicate, equals(SchemaBook.bookFormat));
      expect(result.annotation.literal, isNull);
      expect(result.annotation.iri, isNull);
      expect(result.annotation.localResource, isNull);
      expect(result.annotation.globalResource, isNull);
    });

    test('should process map type property (collection none)', () {
      // Arrange
      final field =
          libraryElement.getClass2('MapNoCollectionTest')!.getField2('reviews');
      expect(field, isNotNull,
          reason: 'Field "reviews" not found in MapNoCollectionTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'Map<String, String>');
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection, RdfCollectionType.none);
      expect(result.annotation.predicate, equals(SchemaBook.reviews));
    });

    test('should process map type property (collection none)', () {
      // Arrange
      final field =
          libraryElement.getClass2('MapNoCollectionTest')!.getField2('reviews');
      expect(field, isNotNull,
          reason: 'Field "reviews" not found in MapNoCollectionTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'Map<String, String>');
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection, RdfCollectionType.none);
      expect(result.annotation.predicate, equals(SchemaBook.reviews));
    });
    test('should process map type property (collection auto)', () {
      // Arrange
      final field = libraryElement
          .getClass2('MapLocalResourceMapperTest')!
          .getField2('reviews');
      expect(field, isNotNull,
          reason: 'Field "reviews" not found in MapLocalResourceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'Map<String, String>');
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection, RdfCollectionType.auto);
      expect(result.annotation.predicate, equals(SchemaBook.reviews));
      expect(result.annotation.localResource, isNotNull);
      expect(result.annotation.localResource!.mapper, isNotNull);
      expect(result.annotation.localResource!.mapper!.name, 'mapEntryMapper');
    });

    test('should process set type property', () {
      // Arrange
      final field = libraryElement.getClass2('SetTest')!.getField2('keywords');
      expect(field, isNotNull, reason: 'Field "keywords" not found in SetTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'Set<String>');
      expect(result.annotation.collection, RdfCollectionType.auto);
      expect(result.annotation.predicate, equals(SchemaBook.keywords));
    });

    test('should process named mapper property', () {
      // Arrange
      final field = libraryElement
          .getClass2('GlobalResourceNamedMapperTest')!
          .getField2('publisher');
      expect(field, isNotNull,
          reason:
              'Field "publisher" not found in GlobalResourceNamedMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.globalResource!.mapper, isNotNull);
      expect(annotation.globalResource!.mapper!.name, 'testNamedMapper');
      expect(annotation.predicate, equals(SchemaBook.publisher));
    });

    test('should process custom mapper with parameters', () {
      // Arrange
      final field =
          libraryElement.getClass2('LiteralNamedMapperTest')!.getField2('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in LiteralNamedMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, 'testCustomMapper');
      expect(annotation.predicate, equals(SchemaBook.isbn));
    });

    test('should process LocalResourceInstanceMapperTest', () {
      // Arrange
      final field = libraryElement
          .getClass2('LocalResourceInstanceMapperTest')!
          .getField2('author');
      expect(field, isNotNull,
          reason:
              'Field "author" not found in LocalResourceInstanceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.name, isNull);
      expect(annotation.localResource!.mapper!.type, isNull);
      expect(annotation.predicate, equals(SchemaBook.author));
      expect(annotation.localResource!.mapper!.instance, isNotNull);
      expect(
          annotation.localResource!.mapper!.instance!.type!.getDisplayString(),
          "LocalResourceMapperImpl");
    });

    test('should process LiteralTypeMapperTest', () {
      // Arrange
      final field =
          libraryElement.getClass2('LiteralTypeMapperTest')!.getField2('price');
      expect(field, isNotNull,
          reason: 'Field "price" not found in LiteralTypeMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, isNull);
      expect(annotation.literal!.mapper!.instance, isNull);
      expect(annotation.literal!.mapper!.type, isNotNull);
      expect(
          annotation.literal!.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(
          annotation.literal!.mapper!.type!.toTypeValue()!.getDisplayString(),
          'LiteralMapperImpl');

      expect(annotation.predicate, equals(SchemaBook.bookFormat));
    });

    test('should process type-based mapper using mapper() constructor', () {
      // Arrange
      final field = libraryElement
          .getClass2('GlobalResourceTypeMapperTest')!
          .getField2('format');
      expect(field, isNotNull,
          reason: 'Field "format" not found in GlobalResourceTypeMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.bookFormat));
    });

    test('should process global resource mapper using mapper() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass2('GlobalResourceMapperTest')!
          .getField2('publisher');
      expect(field, isNotNull,
          reason: 'Field "publisher" not found in GlobalResourceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.publisher));
    });

    test(
        'should process global resource mapper using mapperInstance() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass2('GlobalResourceInstanceMapperTest')!
          .getField2('publisher');
      expect(field, isNotNull,
          reason:
              'Field "publisher" not found in GlobalResourceInstanceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.publisher));
    });

    test('should process local resource mapper using mapper() constructor', () {
      // Arrange
      final field = libraryElement
          .getClass2('LocalResourceMapperTest')!
          .getField2('author');
      expect(field, isNotNull,
          reason: 'Field "author" not found in LocalResourceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.author));
    });

    test('should process literal mapper using mapper() constructor', () {
      // Arrange
      final field =
          libraryElement.getClass2('LiteralMapperTest')!.getField2('pageCount');
      expect(field, isNotNull,
          reason: 'Field "pageCount" not found in LiteralMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.numberOfPages));
    });

    test('should process literal mapper using mapperInstance() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass2('LiteralInstanceMapperTest')!
          .getField2('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in LiteralInstanceMapperTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.predicate, equals(SchemaBook.isbn));
    });
  });
}
