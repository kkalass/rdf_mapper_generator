import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart' as mapper_model;
import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:test/test.dart';

void main() {
  group('extractCustomSerializer', () {
    test('returns null for null property info', () {
      // Arrange
      const fieldName = 'testField';
      const PropertyResolvedModel? propertyInfo = null;
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, isNull);
      expect(result.$2, isNull);
    });

    test('returns null for property without mappings', () {
      // Arrange
      const fieldName = 'testField';
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
        predicate: null,
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
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, isNull);
      expect(result.$2, isNull);
    });

    test('returns iriTermSerializer for IRI mapping with custom mapper', () {
      // Arrange
      const fieldName = 'testField';
      final mockMapper = CustomResolvedMapperModel(
        id: mapper_model.MapperRef.fromInstanceName('testMapper'),
        mappedClass: const Code.literal('TestClass'),
        type: mapper_model.MapperType.iri,
        registerGlobally: false,
        instanceName: 'testMapper',
        customMapperInstanceCode: const Code.literal('TestMapper()'),
        implementationClass: const Code.literal('TestMapperImpl'),
      );
      final iriMapping = IriMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(iriMapping: iriMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('iriTermSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });

    test('returns literalTermSerializer for literal mapping with custom mapper', () {
      // Arrange
      const fieldName = 'testField';
      final mockMapper = CustomResolvedMapperModel(
        id: mapper_model.MapperRef.fromInstanceName('testMapper'),
        mappedClass: const Code.literal('TestClass'),
        type: mapper_model.MapperType.literal,
        registerGlobally: false,
        instanceName: 'testMapper',
        customMapperInstanceCode: const Code.literal('TestMapper()'),
        implementationClass: const Code.literal('TestMapperImpl'),
      );
      final literalMapping = LiteralMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(literalMapping: literalMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('literalTermSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });

    test('returns resourceSerializer for global resource mapping with custom mapper', () {
      // Arrange
      const fieldName = 'testField';
      final mockMapper = CustomResolvedMapperModel(
        id: mapper_model.MapperRef.fromInstanceName('testMapper'),
        mappedClass: const Code.literal('TestClass'),
        type: mapper_model.MapperType.globalResource,
        registerGlobally: false,
        instanceName: 'testMapper',
        customMapperInstanceCode: const Code.literal('TestMapper()'),
        implementationClass: const Code.literal('TestMapperImpl'),
      );
      final globalResourceMapping = GlobalResourceMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(globalResourceMapping: globalResourceMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('resourceSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });

    test('returns resourceSerializer for local resource mapping with custom mapper', () {
      // Arrange
      const fieldName = 'testField';
      final mockMapper = CustomResolvedMapperModel(
        id: mapper_model.MapperRef.fromInstanceName('testMapper'),
        mappedClass: const Code.literal('TestClass'),
        type: mapper_model.MapperType.localResource,
        registerGlobally: false,
        instanceName: 'testMapper',
        customMapperInstanceCode: const Code.literal('TestMapper()'),
        implementationClass: const Code.literal('TestMapperImpl'),
      );
      final localResourceMapping = LocalResourceMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(localResourceMapping: localResourceMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('resourceSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });

    test('returns complex mapper serializer code for generated mapper with dependencies', () {
      // Arrange
      const fieldName = 'testField';
      final mockGeneratedMapper = ResourceResolvedMapperModel(
        id: mapper_model.MapperRef.fromImplementationClass(const Code.literal('TestClassMapper')),
        mappedClass: const Code.literal('TestClass'),
        mappedClassModel: MappedClassResolvedModel(
          className: const Code.literal('TestClass'),
          properties: const [],
          isRdfFieldFilter: (property) => property.isRdfProperty,
        ),
        implementationClass: const Code.literal('TestClassMapper'),
        registerGlobally: false,
        typeIri: null,
        termClass: const Code.literal('Term'),
        iriStrategy: null,
        needsReader: false,
        dependencies: [
          DependencyResolvedModel(
            id: mapper_model.DependencyId('test-dep-id'),
            field: FieldResolvedModel(
              name: '_baseUri',
              type: const Code.literal('String Function()'),
              isLate: false,
              isFinal: true,
            ),
            constructorParam: ConstructorParameterResolvedModel(
              type: const Code.literal('String Function()'),
              paramName: 'baseUri',
              defaultValue: null,
            ),
            usageCode: const Code.literal('_baseUri'),
          ),
        ],
        provides: const [],
      );
      final iriMapping = IriMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockGeneratedMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(iriMapping: iriMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{
        'baseUri': ProvidesResolvedModel(name: 'baseUri', dartPropertyName: 'id'),
      };

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('iriTermSerializer'));
      expect(result.$2, isNotNull);
      final codeString = result.$2.toString();
      expect(codeString, contains('TestClassMapper'));
      expect(codeString, contains('baseUri: () => resource.id'));
    });

    test('handles generated mapper with injected dependencies only', () {
      // Arrange
      const fieldName = 'testField';
      final mockGeneratedMapper = ResourceResolvedMapperModel(
        id: mapper_model.MapperRef.fromImplementationClass(const Code.literal('TestClassMapper')),
        mappedClass: const Code.literal('TestClass'),
        mappedClassModel: MappedClassResolvedModel(
          className: const Code.literal('TestClass'),
          properties: const [],
          isRdfFieldFilter: (property) => property.isRdfProperty,
        ),
        implementationClass: const Code.literal('TestClassMapper'),
        registerGlobally: false,
        typeIri: null,
        termClass: const Code.literal('Term'),
        iriStrategy: null,
        needsReader: false,
        dependencies: [
          DependencyResolvedModel(
            id: mapper_model.DependencyId('test-dep-id'),
            field: FieldResolvedModel(
              name: '_otherMapper',
              type: const Code.literal('OtherMapper'),
              isLate: false,
              isFinal: true,
            ),
            constructorParam: ConstructorParameterResolvedModel(
              type: const Code.literal('OtherMapper'),
              paramName: 'otherMapper',
              defaultValue: null,
            ),
            usageCode: const Code.literal('_otherMapper'),
          ),
        ],
        provides: const [],
      );
      final iriMapping = IriMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockGeneratedMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(iriMapping: iriMapping);
      // No provides - all dependencies should be injected
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('iriTermSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });

    test('handles generated mapper with no dependencies', () {
      // Arrange
      const fieldName = 'testField';
      final mockGeneratedMapper = ResourceResolvedMapperModel(
        id: mapper_model.MapperRef.fromImplementationClass(const Code.literal('TestClassMapper')),
        mappedClass: const Code.literal('TestClass'),
        mappedClassModel: MappedClassResolvedModel(
          className: const Code.literal('TestClass'),
          properties: const [],
          isRdfFieldFilter: (property) => property.isRdfProperty,
        ),
        implementationClass: const Code.literal('TestClassMapper'),
        registerGlobally: false,
        typeIri: null,
        termClass: const Code.literal('Term'),
        iriStrategy: null,
        needsReader: false,
        dependencies: const [], // No dependencies
        provides: const [],
      );
      final iriMapping = IriMappingResolvedModel(
        hasMapper: true,
        resolvedMapper: mockGeneratedMapper,
      );
      final propertyInfo = _createPropertyResolvedModel(iriMapping: iriMapping);
      const providesByConstructorParameterNames = <String, ProvidesResolvedModel>{};

      // Act
      final result = extractCustomSerializer(
        fieldName,
        propertyInfo,
        providesByConstructorParameterNames,
      );

      // Assert
      expect(result.$1, equals('iriTermSerializer'));
      expect(result.$2, isNotNull);
      expect(result.$2.toString(), equals('_testFieldMapper'));
    });
  });
}

// Helper function to create PropertyResolvedModel with minimal required fields
PropertyResolvedModel _createPropertyResolvedModel({
  IriMappingResolvedModel? iriMapping,
  LiteralMappingResolvedModel? literalMapping,
  GlobalResourceMappingResolvedModel? globalResourceMapping,
  LocalResourceMappingResolvedModel? localResourceMapping,
}) {
  return PropertyResolvedModel(
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
    iriMapping: iriMapping,
    literalMapping: literalMapping,
    globalResourceMapping: globalResourceMapping,
    localResourceMapping: localResourceMapping,
  );
}
