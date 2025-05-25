import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';
import 'package:test/test.dart';
import 'package:rdf_vocabularies/schema.dart';

import '../test_helper.dart';

void main() {
  group('GlobalResourceProcessor', () {
    late ClassElement2 bookClass;
    late ClassElement2 personClass;
    late ClassElement2 invalidClass;
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      libraryElement = await analyzeTestFile('test_models.dart');
      bookClass = libraryElement.getClass2('Book')!;
      personClass = libraryElement.getClass2('Person')!;
      invalidClass = libraryElement.getClass2('NotAnnotated')!;
    });

    test('should process ClassWithEmptyIriStrategy', () {
      // Act
      final result = GlobalResourceProcessor.processClass(
          libraryElement.getClass2('ClassWithEmptyIriStrategy')!);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'ClassWithEmptyIriStrategy');
      expect(result.annotation.classIri, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.iri,
          equals(IriStrategyInfo(mapper: null, template: null)));
      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(0));
    });

    test('should process class with RdfGlobalResource annotation', () {
      // Act
      final result = GlobalResourceProcessor.processClass(bookClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'Book');
      expect(result.annotation.classIri, equals(SchemaBook.classIri));
      expect(result.annotation.registerGlobally, isTrue);
      expect(result.annotation.classIri, isA<IriTerm>());
      expect(result.annotation.iri, isA<IriStrategy>());
    });

    test('should return null for class without RdfGlobalResource annotation',
        () {
      // Act
      final result = GlobalResourceProcessor.processClass(invalidClass);

      // Assert
      expect(result, isNull);
    });

    test('should extract constructors', () {
      // Act
      final result = GlobalResourceProcessor.processClass(bookClass);

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
      final result = GlobalResourceProcessor.processClass(bookClass);

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

    test('should handle class with custom type IRI and registerGlobally false',
        () {
      // Act
      final result = GlobalResourceProcessor.processClass(personClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'Person');
      expect(result.annotation.classIri, equals(SchemaPerson.classIri));
      expect(result.annotation.registerGlobally, isFalse);
    });
  });
}
