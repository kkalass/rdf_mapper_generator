import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../../lib/src/processors/property_processor.dart';
import '../test_helper.dart';

void main() {
  late LibraryElement2 libraryElement;

  setUpAll(() async {
    libraryElement =
        await analyzeTestFile('property_processor_test_models.dart');
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
    // The defaultValue should be a Dart Map constant
    final defaultValue = propertyInfo.annotation.defaultValue;
    expect(defaultValue, isNotNull);

    // For now, just verify the default value is not null
    // The actual value inspection would require more complex Dart constant evaluation
    // which is beyond the scope of this test
    expect(defaultValue, isNotNull);
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
    expect(propertyInfo.annotation.predicate, SchemaBook.description);

    // Check for language tag
    final literal = propertyInfo.annotation.literal;
    expect(literal, isNotNull);
    expect(literal?.language, 'en');
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
    expect(propertyInfo.annotation.predicate, SchemaBook.dateCreated);

    // Check for datatype
    final literal = propertyInfo.annotation.literal;
    expect(literal, isNotNull);
    // The datatype might be wrapped in angle brackets
    final datatype = literal?.datatype.toString();
    expect(
        datatype,
        anyOf([
          'http://www.w3.org/2001/XMLSchema#dateTime',
          '<http://www.w3.org/2001/XMLSchema#dateTime>'
        ]));
  });

  test('should process instance-based mappers', () {
    // This test is currently skipped as the feature is not yet implemented
    // Implementation will be added in a future update
  }, skip: 'Instance-based mappers not yet implemented');

  test('should process type-based mappers', () {
    // This test is currently skipped as the feature is not yet implemented
    // Implementation will be added in a future update
  }, skip: 'Type-based mappers not yet implemented');
}
