import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('GlobalResourceProcessor', () {
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('global_resource_processor_test_models.dart');
    });

    test('should process ClassWithEmptyIriStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithEmptyIriStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithEmptyIriStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, '{+iri}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithEmptyIriStrategyNoRegisterGlobally', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext,
          libraryElement
              .getClass2('ClassWithEmptyIriStrategyNoRegisterGlobally')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithEmptyIriStrategyNoRegisterGlobally');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, '{+iri}');
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithIriTemplateStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriTemplateStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriTemplateStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri?.mapper, isNull);
      expect(
          annotation.iri?.template, equals('http://example.org/persons/{id}'));
      expect(annotation.iri?.templateInfo, isNotNull);
      expect(annotation.iri?.templateInfo?.isValid, isTrue);
      expect(annotation.iri?.templateInfo?.variables, contains('id'));
      expect(
          annotation.iri?.templateInfo?.propertyVariables.map((pn) => pn.name),
          contains('id'));
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithIriMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNotNull);
      expect(annotation.iri!.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(annotation.iri!.mapper!.type!.toTypeValue()!.getDisplayString(),
          'TestIriMapper');
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNotNull);
      expect(annotation.iri!.mapper!.instance!.type!.getDisplayString(),
          'TestIriMapper2');
      expect(annotation.iri!.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithMapperNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals('testGlobalResourceMapper'));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(annotation.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(annotation.mapper!.type!.toTypeValue()!.getDisplayString(),
          'TestGlobalResourceMapper');
      expect(annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestGlobalResourceMapper');
      expect(annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });

    test('should process class with RdfGlobalResource annotation', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.Book');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.classIri!.value, isA<IriTerm>());
      expect(annotation.iri, isA<IriStrategyInfo>());
    });

    test('should return null for class without RdfGlobalResource annotation',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('NotAnnotated')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNull);
    });

    test('should extract constructors', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.constructors, isNotEmpty);

      // Check that we have at least one constructor
      final defaultConstructor = result.constructors.firstWhere(
        (c) => c.name == '' || c.name == 'Book',
        orElse: () => throw StateError('No default constructor found'),
      );

      expect(defaultConstructor, isNotNull);
      expect(defaultConstructor.isConst, isFalse);
      expect(defaultConstructor.isFactory, isFalse);
    });

    test('should extract fields', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.fields, isNotEmpty);

      // Check that we have the expected fields
      final titleField = result.fields.firstWhere(
        (f) => f.name == 'title',
      );

      expect(titleField, isNotNull);
      expect(titleField.type, 'String');
      expect(titleField.isFinal, isTrue);
    });
    test('should process ClassWithIriMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      final mapperType = annotation.iri!.mapper!.type;
      expect(mapperType, isNotNull);
      expect(mapperType.toString(), contains('TestIriMapper'));
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
    });

    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      final instance = annotation.iri!.mapper!.instance;
      expect(instance, isNotNull);
      expect(instance.toString(), contains('TestIriMapper'));
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNull);
    });

    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, 'testMapper');
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
    });
  });
}
