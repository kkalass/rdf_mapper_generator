import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:test/test.dart';

void main() {
  group('getReaderMethod', () {
    test('returns getMap for Map collections', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: true,
        dartType: const Code.literal('Map<String, String>'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.auto,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getReaderMethod(propertyInfo, false);

      // Assert
      expect(result.toString(), equals('getMap'));
    });

    test('returns getValues<ElementType> for Iterable collections', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: false,
        dartType: const Code.literal('List<String>'),
        isList: true,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: false,
          isIterable: true,
          elementTypeCode: Code.literal('String'),
        ),
        collectionType: RdfCollectionType.auto,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getReaderMethod(propertyInfo, false);

      // Assert
      expect(result.toString(), equals('getValues<String>'));
    });

    test('returns require for required non-collection properties', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: true,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: false,
        isMap: false,
        dartType: const Code.literal('String'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: false,
          isMap: false,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.none,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getReaderMethod(propertyInfo, true);

      // Assert
      expect(result.toString(), equals('require'));
    });

    test('returns optional for non-required non-collection properties', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: true,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: false,
        isMap: false,
        dartType: const Code.literal('String'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: false,
          isMap: false,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.none,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getReaderMethod(propertyInfo, false);

      // Assert
      expect(result.toString(), equals('optional'));
    });

    test('returns optional for collections with RdfCollectionType.none', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: true,
        dartType: const Code.literal('Map<String, String>'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.none,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getReaderMethod(propertyInfo, false);

      // Assert
      expect(result.toString(), equals('optional'));
    });
  });

  group('getSerializerMethod', () {
    test('returns addMap for Map collections', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: true,
        dartType: const Code.literal('Map<String, String>'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.auto,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getSerializerMethod(propertyInfo);

      // Assert
      expect(result.toString(), equals('addMap'));
    });

    test('returns addValues<ElementType> for Iterable collections', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: false,
        dartType: const Code.literal('List<String>'),
        isList: true,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: false,
          isIterable: true,
          elementTypeCode: Code.literal('String'),
        ),
        collectionType: RdfCollectionType.auto,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getSerializerMethod(propertyInfo);

      // Assert
      expect(result.toString(), equals('addValues<String>'));
    });

    test('returns addValue for non-collection properties', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: false,
        isMap: false,
        dartType: const Code.literal('String'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: false,
          isMap: false,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.none,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getSerializerMethod(propertyInfo);

      // Assert
      expect(result.toString(), equals('addValue'));
    });

    test('returns addValue for collections with RdfCollectionType.none', () {
      // Arrange
      final propertyInfo = PropertyResolvedModel(
        propertyName: 'testProperty',
        isRequired: false,
        isFieldNullable: false,
        isRdfProperty: true,
        isIriPart: false,
        isRdfValue: false,
        isRdfLanguageTag: false,
        iriPartName: null,
        constructorParameterName: null,
        isNamedConstructorParameter: false,
        include: true,
        predicate: const Code.literal('http://example.org/pred'),
        defaultValue: null,
        hasDefaultValue: false,
        includeDefaultsInSerialization: false,
        isCollection: true,
        isMap: true,
        dartType: const Code.literal('Map<String, String>'),
        isList: false,
        isSet: false,
        collectionInfo: const CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          isIterable: false,
          elementTypeCode: null,
        ),
        collectionType: RdfCollectionType.none,
        iriMapping: null,
        literalMapping: null,
        globalResourceMapping: null,
        localResourceMapping: null,
      );

      // Act
      final result = getSerializerMethod(propertyInfo);

      // Assert
      expect(result.toString(), equals('addValue'));
    });
  });
}
