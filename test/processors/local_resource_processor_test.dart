import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

final stringType = Code.coreType('String');
void main() {
  group('LocalResourceProcessor', () {
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('local_resource_processor_test_models.dart');
    });

    test('should process ClassNoRegisterGlobally', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassNoRegisterGlobally')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassNoRegisterGlobally');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
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
          result!.className.code, 'lrptm.ClassWithMapperNamedMapperStrategy');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals('testLocalResourceMapper'));
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
      expect(result!.className.code, 'lrptm.ClassWithMapperStrategy');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(annotation.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(annotation.mapper!.type!.toTypeValue()!.getDisplayString(),
          'TestLocalResourceMapper');
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
      expect(result!.className.code, 'lrptm.ClassWithMapperInstanceStrategy');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestLocalResourceMapper2');
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
      expect(result!.className.code, 'lrptm.Book');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.classIri!.value, isA<IriTerm>());
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
      expect(titleField.type, stringType);
      expect(titleField.isFinal, isTrue);
    });

    test('should process ClassWithPositionalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithPositionalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithPositionalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check constructor has positional parameter
      final constructor = result.constructors.first;
      expect(constructor.parameters.first.isPositional, isTrue);
      expect(constructor.parameters.first.name, equals('name'));
    });
    test('should process ClassWithNoRdfType', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('ClassWithNoRdfType')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithNoRdfType');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));

      // Check constructor has positional parameter
      final constructor = result.constructors.first;
      expect(constructor.parameters.first.isPositional, isTrue);
      expect(constructor.parameters.first.name, equals('name'));
    });

    test('should process ClassWithNonFinalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithNonFinalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithNonFinalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check field is not final
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isFalse);
      expect(nameField.type, equals(stringType));
    });

    test('should process ClassWithNonFinalPropertyWithDefault', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithNonFinalPropertyWithDefault')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'lrptm.ClassWithNonFinalPropertyWithDefault');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check field is not final and has default value
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isFalse);
      expect(nameField.type, equals(stringType));
    });

    test('should process ClassWithNonFinalOptionalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithNonFinalOptionalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithNonFinalOptionalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check field is nullable and not final
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isFalse);
      expect(nameField.type, equals(Code.coreType('String?')));
    });

    test('should process ClassWithLateNonFinalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithLateNonFinalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithLateNonFinalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check field is late and not final
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isFalse);
      expect(nameField.type, equals(stringType));
      expect(nameField.isLate, isTrue);
    });

    test('should process ClassWithLateFinalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithLateFinalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lrptm.ClassWithLateFinalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));

      // Check field is late final
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isTrue);
      expect(nameField.type, equals(stringType));
      expect(nameField.isLate, isTrue);
    });

    test('should process ClassWithMixedFinalAndLateFinalProperty', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass2('ClassWithMixedFinalAndLateFinalProperty')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'lrptm.ClassWithMixedFinalAndLateFinalProperty');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));

      // Check name field is final
      final nameField = result.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isFinal, isTrue);
      expect(nameField.type, equals(stringType));
      expect(nameField.isLate, isFalse);

      // Check age field is late final
      final ageField = result.fields.firstWhere((f) => f.name == 'age');
      expect(ageField.isFinal, isTrue);
      expect(ageField.type, equals(Code.coreType('int')));
      expect(ageField.isLate, isTrue);
    });
  });
}
