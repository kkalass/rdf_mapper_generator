import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
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
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithEmptyIriStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithEmptyIriStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri?.mapper, isNull);
      expect(result.annotation.iri?.template, '{+iri}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithEmptyIriStrategyNoRegisterGlobally', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(
          validationContext,
          libraryElement
              .getClass2('ClassWithEmptyIriStrategyNoRegisterGlobally')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithEmptyIriStrategyNoRegisterGlobally');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isFalse);
      expect(result.annotation.iri?.mapper, isNull);
      expect(result.annotation.iri?.template, '{+iri}');
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithIriTemplateStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriTemplateStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriTemplateStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.mapper, isNull);
      expect(result.annotation.iri?.mapper, isNull);
      expect(result.annotation.iri?.template,
          equals('http://example.org/persons/{id}'));
      expect(result.annotation.iri?.templateInfo, isNotNull);
      expect(result.annotation.iri?.templateInfo?.isValid, isTrue);
      expect(result.annotation.iri?.templateInfo?.variables, contains('id'));
      expect(
          result.annotation.iri?.templateInfo?.propertyVariables
              .map((pn) => pn.name),
          contains('id'));
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.mapper, isNull);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.template, isNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      expect(result.annotation.iri!.mapper!.name, equals('testMapper'));
      expect(result.annotation.iri!.mapper!.type, isNull);
      expect(result.annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithIriMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.mapper, isNull);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.template, isNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      expect(result.annotation.iri!.mapper!.name, isNull);
      expect(result.annotation.iri!.mapper!.type, isNotNull);
      expect(result.annotation.iri!.mapper!.type!.type!.getDisplayString(),
          'Type');
      expect(
          result.annotation.iri!.mapper!.type!
              .toTypeValue()!
              .getDisplayString(),
          'TestIriMapper');
      expect(result.annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.mapper, isNull);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.template, isNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      expect(result.annotation.iri!.mapper!.name, isNull);
      expect(result.annotation.iri!.mapper!.type, isNull);
      expect(result.annotation.iri!.mapper!.instance, isNotNull);
      expect(result.annotation.iri!.mapper!.instance!.type!.getDisplayString(),
          'TestIriMapper2');
      expect(result.annotation.iri!.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithMapperNamedMapperStrategy');
      expect(result.annotation.classIri, isNull);
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNull);
      expect(result.annotation.mapper, isNotNull);
      expect(
          result.annotation.mapper!.name, equals('testGlobalResourceMapper'));
      expect(result.annotation.mapper!.type, isNull);
      expect(result.annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperStrategy');
      expect(result.annotation.classIri, isNull);
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNull);
      expect(result.annotation.mapper, isNotNull);
      expect(result.annotation.mapper!.name, isNull);
      expect(result.annotation.mapper!.type, isNotNull);
      expect(result.annotation.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(result.annotation.mapper!.type!.toTypeValue()!.getDisplayString(),
          'TestGlobalResourceMapper');
      expect(result.annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });
    test('should process ClassWithMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperInstanceStrategy');
      expect(result.annotation.classIri, isNull);
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNull);
      expect(result.annotation.mapper, isNotNull);
      expect(result.annotation.mapper!.name, isNull);
      expect(result.annotation.mapper!.type, isNull);
      expect(result.annotation.mapper!.instance, isNotNull);
      expect(result.annotation.mapper!.instance!.type!.getDisplayString(),
          'TestGlobalResourceMapper');
      expect(result.annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });

    test('should process class with RdfGlobalResource annotation', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.Book');
      expect(result.annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.classIri!.value, isA<IriTerm>());
      expect(result.annotation.iri, isA<IriStrategyInfo>());
    });

    test('should return null for class without RdfGlobalResource annotation',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('NotAnnotated')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNull);
    });

    test('should extract constructors', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(
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
      final result = GlobalResourceProcessor.processClass(
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
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      final mapperType = result.annotation.iri!.mapper!.type;
      expect(mapperType, isNotNull);
      expect(mapperType.toString(), contains('TestIriMapper'));
      expect(result.annotation.iri!.mapper!.name, isNull);
      expect(result.annotation.iri!.mapper!.instance, isNull);
    });

    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      final instance = result.annotation.iri!.mapper!.instance;
      expect(instance, isNotNull);
      expect(instance.toString(), contains('TestIriMapper'));
      expect(result.annotation.iri!.mapper!.name, isNull);
      expect(result.annotation.iri!.mapper!.type, isNull);
    });

    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = GlobalResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      expect(result.annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.mapper, isNotNull);
      expect(result.annotation.iri!.mapper!.name, 'testMapper');
      expect(result.annotation.iri!.mapper!.type, isNull);
      expect(result.annotation.iri!.mapper!.instance, isNull);
    });
  });
}
