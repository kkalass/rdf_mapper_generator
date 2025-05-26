import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late final ClassElement2 noAnnotationClass;
  late final ClassElement2 testClass;
  late final LibraryElement2 libraryElement;

  setUpAll(() async {
    libraryElement =
        await analyzeTestFile('property_processor_test_models.dart');
    noAnnotationClass = libraryElement.getClass2('NoAnnotationTest')!;
    testClass = libraryElement.getClass2('SimplePropertyTest')!;
  });

  group('PropertyProcessor', () {
    test('should return null for field without RdfProperty annotation', () {
      // Arrange
      final field = noAnnotationClass.getField2('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in NoAnnotationTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNull);
    });

    test('should process simple property', () {
      // Arrange
      final field = testClass.getField2('name');
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
      expect(result!.annotation.include, isFalse);
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

    test('should process collection properties', () {
      // Test collection
      final field =
          libraryElement.getClass2('CollectionTest')!.getField2('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionTest');

      final result = PropertyProcessor.processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
    });

    test('should process enum type property', () {
      // Arrange
      final field =
          libraryElement.getClass2('ComplexTypeTest')!.getField2('format');
      expect(field, isNotNull,
          reason: 'Field "format" not found in ComplexTypeTest');

      // Act
      final result = PropertyProcessor.processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, 'BookFormatType');
    });
  });
}
