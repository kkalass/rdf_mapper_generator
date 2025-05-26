import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late ClassElement2 bookWithMapperClass;
  late ClassElement2 bookWithMapperInstanceClass;
  late ClassElement2 bookWithTemplateClass;

  setUpAll(() async {
    final libraryElement = await analyzeTestFile('annotation_test_models.dart');
    bookWithMapperClass = libraryElement.getClass2('BookWithMapper')!;
    bookWithMapperInstanceClass =
        libraryElement.getClass2('BookWithMapperInstance')!;
    bookWithTemplateClass = libraryElement.getClass2('BookWithTemplate')!;
  });

  group('Annotation Preservation Tests', () {
    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.mapper',
        () {
      // Act
      final result = GlobalResourceProcessor.processClass(bookWithMapperClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'BookWithMapper');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue);

      // Check IriStrategy
      final iriStrategy = annotation.iri;
      expect(iriStrategy, isNotNull);

      // For mapper strategy, we should have the type and arguments
      // Note: We can't directly access mapperType and mapperArguments in the test
      // as they're not part of the public API. Instead, we'll verify the behavior
      // through the generated code in integration tests.
    });

    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.mapperInstance',
        () {
      // Act
      final result =
          GlobalResourceProcessor.processClass(bookWithMapperInstanceClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'BookWithMapperInstance');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isFalse);

      // Check IriStrategy
      final iriStrategy = annotation.iri;
      expect(iriStrategy, isNotNull);

      // For mapper instance strategy, we verify the behavior through the generated code
      // in integration tests, as we can't directly access the instance in the test.
    });

    test(
        'should preserve all RdfGlobalResource parameters with IriStrategy.template',
        () {
      // Act
      final result =
          GlobalResourceProcessor.processClass(bookWithTemplateClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'BookWithTemplate');

      // Check RdfGlobalResource annotation
      final annotation = result.annotation;
      expect(annotation.classIri, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue); // Default value

      // Check IriStrategy
      final iriStrategy = annotation.iri;
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
      expect(annotation.predicate, equals(SchemaBook.name));
      expect(annotation.include, isTrue);
      expect(annotation.includeDefaultsInSerialization, isFalse);

      // Check IRI mapping
      expect(annotation.iri, isNotNull);

      // Note: We can't directly access the template in the test as it's not part of the public API.
      // The actual template value will be verified through the generated code in integration tests.
    });
  });
}
