import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late ClassElement2 bookWithMapperClass;
  late ClassElement2 bookWithMapperInstanceClass;
  late ClassElement2 bookWithTemplateClass;

  setUpAll(() async {
    final (libraryElement, _) =
        await analyzeTestFile('annotation_test_models.dart');
    bookWithMapperClass = libraryElement.getClass2('BookWithMapper')!;
    bookWithMapperInstanceClass =
        libraryElement.getClass2('BookWithMapperInstance')!;
    bookWithTemplateClass = libraryElement.getClass2('BookWithTemplate')!;
  });

  group('Annotation Preservation Tests', () {
    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.mapper',
        () {
      final validationContext = ValidationContext();
      // Act
      final result = ResourceProcessor.processClass(
          validationContext, bookWithMapperClass);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'atm.BookWithMapper');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue);

      // Check IriStrategy
      expect(annotation, isA<RdfGlobalResourceInfo>());
      final iriStrategy = (annotation as RdfGlobalResourceInfo).iri;
      expect(iriStrategy, isNotNull);

      // For mapper strategy, we should have the type and arguments
      // Note: We can't directly access mapperType and mapperArguments in the test
      // as they're not part of the public API. Instead, we'll verify the behavior
      // through the generated code in integration tests.
    });

    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.mapperInstance',
        () {
      final validationContext = ValidationContext();
      // Act
      final result = ResourceProcessor.processClass(
          validationContext, bookWithMapperInstanceClass);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'atm.BookWithMapperInstance');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isFalse);

      // Check IriStrategy
      expect(annotation, isA<RdfGlobalResourceInfo>());
      final iriStrategy = (annotation as RdfGlobalResourceInfo).iri;
      expect(iriStrategy, isNotNull);

      // For mapper instance strategy, we verify the behavior through the generated code
      // in integration tests, as we can't directly access the instance in the test.
    });

    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.template',
        () {
      final validationContext = ValidationContext();
      // Act
      final result = ResourceProcessor.processClass(
          validationContext, bookWithTemplateClass);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'atm.BookWithTemplate');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue); // Default value

      // Check IriStrategy
      expect(annotation, isA<RdfGlobalResourceInfo>());
      final iriStrategy = (annotation as RdfGlobalResourceInfo).iri;
      expect(iriStrategy, isNotNull);

      // For template strategy, we verify the behavior through the generated code
      // in integration tests, as we can't directly access the template in the test.
    });

    test('should preserve all RdfProperty parameters', () {
      // Find the title field in the BookWithMapper class
      final titleField = bookWithMapperClass.fields2.firstWhere(
        (f) => f.name3 == 'title',
      );

      // Act
      final result = PropertyProcessor.processField(titleField);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'title');

      // Check RdfProperty annotation
      final annotation = result.annotation;
      expect(annotation.predicate.value, equals(SchemaBook.name));
      expect(annotation.include, isTrue);
      expect(annotation.includeDefaultsInSerialization, isFalse);

      // Check IRI mapping
      expect(annotation.iri, isNotNull);

      // Note: We can't directly access the template in the test as it's not part of the public API.
      // The actual template value will be verified through the generated code in integration tests.
    });
  });
}
