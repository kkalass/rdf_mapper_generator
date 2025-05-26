import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:rdf_vocabularies/xsd.dart';
import 'package:test/test.dart';

import '../../lib/src/processors/property_processor.dart';
import '../test_helper.dart';

void main() {
  late LibraryElement2 libraryElement;

  setUpAll(() async {
    libraryElement = await analyzeTestFile('property_processor_test_models.dart');
  });

  test('should process complex default value', () {
    // Arrange
    final classElement = libraryElement.getClass2('ComplexDefaultValueTest');
    if (classElement == null) {
      fail('Class ComplexDefaultValueTest not found in test models');
    }
    
    final field = classElement.getField2('complexValue');
    if (field == null) {
      fail('Field "complexValue" not found in ComplexDefaultValueTest');
    }

    // Act
    final result = PropertyProcessor.processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.defaultValue, '{\"id\":\"1\",\"name\":\"Test\"}');
    // Check for the presence of fromJson/toJson functions in the annotation
    expect(propertyInfo.annotation.toString(), contains('fromJson'));
    expect(propertyInfo.annotation.toString(), contains('toJson'));
  });

  test('should process late properties', () {
    // Arrange
    final classElement = libraryElement.getClass2('LatePropertyTest');
    if (classElement == null) {
      fail('Class LatePropertyTest not found in test models');
    }
    
    final nameField = classElement.getField2('name');
    final descriptionField = classElement.getField2('description');
    
    if (nameField == null) {
      fail('Field "name" not found in LatePropertyTest');
    }
    if (descriptionField == null) {
      fail('Field "description" not found in LatePropertyTest');
    }

    // Act
    final nameResult = PropertyProcessor.processField(nameField);
    final descriptionResult = PropertyProcessor.processField(descriptionField);

    // Assert
    expect(nameResult, isNotNull);
    expect(descriptionResult, isNotNull);
    expect(nameResult!.annotation.predicate, SchemaBook.name);
    expect(descriptionResult!.annotation.predicate, SchemaBook.description);
  });

  test('should process mutable properties with getters/setters', () {
    // Arrange
    final classElement = libraryElement.getClass2('MutablePropertyTest');
    if (classElement == null) {
      fail('Class MutablePropertyTest not found in test models');
    }
    
    final nameField = classElement.getField2('name');
    final descriptionField = classElement.getField2('description');
    
    if (nameField == null) {
      fail('Field "name" not found in MutablePropertyTest');
    }
    if (descriptionField == null) {
      fail('Field "description" not found in MutablePropertyTest');
    }

    // Act
    final nameResult = PropertyProcessor.processField(nameField);
    final descriptionResult = PropertyProcessor.processField(descriptionField);

    // Assert
    expect(nameResult, isNotNull);
    expect(descriptionResult, isNotNull);
    expect(nameResult!.annotation.predicate, SchemaBook.name);
    expect(descriptionResult!.annotation.predicate, SchemaBook.description);
  });

  test('should process literal with language tag', () {
    // Arrange
    final classElement = libraryElement.getClass2('LanguageTagTest');
    if (classElement == null) {
      fail('Class LanguageTagTest not found in test models');
    }
    
    final field = classElement.getField2('description');
    if (field == null) {
      fail('Field "description" not found in LanguageTagTest');
    }

    // Act
    final result = PropertyProcessor.processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.literal, isNotNull);
    expect(propertyInfo.annotation.literal!.language, 'en');
  });

  test('should process literal with datatype', () {
    // Arrange
    final classElement = libraryElement.getClass2('DatatypeTest');
    if (classElement == null) {
      fail('Class DatatypeTest not found in test models');
    }
    
    final field = classElement.getField2('date');
    if (field == null) {
      fail('Field "date" not found in DatatypeTest');
    }

    // Act
    final result = PropertyProcessor.processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.literal, isNotNull);
    expect(propertyInfo.annotation.literal!.datatype, Xsd.dateTime);
  });

  test('should process instance-based mappers', () {
    // Arrange
    final classElement = libraryElement.getClass2('InstanceBasedMappersTest');
    if (classElement == null) {
      fail('Class InstanceBasedMappersTest not found in test models');
    }
    
    final authorField = classElement.getField2('author');
    final publisherField = classElement.getField2('publisher');
    final bookIdField = classElement.getField2('bookId');
    final priceField = classElement.getField2('price');
    
    if (authorField == null) fail('Field "author" not found');
    if (publisherField == null) fail('Field "publisher" not found');
    if (bookIdField == null) fail('Field "bookId" not found');
    if (priceField == null) fail('Field "price" not found');

    // Act
    final authorResult = PropertyProcessor.processField(authorField);
    final publisherResult = PropertyProcessor.processField(publisherField);
    final bookIdResult = PropertyProcessor.processField(bookIdField);
    final priceResult = PropertyProcessor.processField(priceField);

    // Assert
    expect(authorResult, isNotNull);
    expect(publisherResult, isNotNull);
    expect(bookIdResult, isNotNull);
    expect(priceResult, isNotNull);
    
    expect(authorResult!.annotation.localResource, isNotNull);
    expect(publisherResult!.annotation.globalResource, isNotNull);
    expect(bookIdResult!.annotation.iri, isNotNull);
    expect(priceResult!.annotation.literal, isNotNull);
  });

  test('should process type-based mappers', () {
    // Arrange
    final classElement = libraryElement.getClass2('TypeBasedMappersTest');
    if (classElement == null) {
      fail('Class TypeBasedMappersTest not found in test models');
    }
    
    final authorField = classElement.getField2('author');
    final publisherField = classElement.getField2('publisher');
    final bookIdField = classElement.getField2('bookId');
    final priceField = classElement.getField2('price');
    
    if (authorField == null) fail('Field "author" not found');
    if (publisherField == null) fail('Field "publisher" not found');
    if (bookIdField == null) fail('Field "bookId" not found');
    if (priceField == null) fail('Field "price" not found');

    // Act
    final authorResult = PropertyProcessor.processField(authorField);
    final publisherResult = PropertyProcessor.processField(publisherField);
    final bookIdResult = PropertyProcessor.processField(bookIdField);
    final priceResult = PropertyProcessor.processField(priceField);

    // Assert
    expect(authorResult, isNotNull);
    expect(publisherResult, isNotNull);
    expect(bookIdResult, isNotNull);
    expect(priceResult, isNotNull);
    
    expect(authorResult!.annotation.localResource, isNotNull);
    expect(publisherResult!.annotation.globalResource, isNotNull);
    expect(bookIdResult!.annotation.iri, isNotNull);
    expect(priceResult!.annotation.literal, isNotNull);
  });

  test('should process collection with custom from/to JSON', () {
    // Arrange
    final classElement = libraryElement.getClass2('CollectionWithCustomJsonTest');
    if (classElement == null) {
      fail('Class CollectionWithCustomJsonTest not found in test models');
    }
    
    final field = classElement.getField2('keywords');
    if (field == null) {
      fail('Field "keywords" not found in CollectionWithCustomJsonTest');
    }

    // Act
    final result = PropertyProcessor.processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.collection, RdfCollectionType.none);
    // Check for the presence of fromJson/toJson functions in the annotation
    expect(propertyInfo.annotation.toString(), contains('fromJson'));
    expect(propertyInfo.annotation.toString(), contains('toJson'));
  });
}
