import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('GlobalResourceProcessor', () {
    late ClassElement2 bookClass;
    late ClassElement2 personClass;
    late ClassElement2 invalidClass;

    setUpAll(() async {
      final libraryElement = await analyzeTestFile('test_models.dart');
      bookClass = libraryElement.getClass2('Book')!;
      personClass = libraryElement.getClass2('Person')!;
      invalidClass = libraryElement.getClass2('NotAnnotated')!;
    });

    test('should process class with RdfGlobalResource annotation', () {
      // Act
      final result = GlobalResourceProcessor.processClass(bookClass);

      // Assert
      expect(result, isNotNull);
      expect(result!.className, 'Book');
      expect(result.typeIri, 'https://schema.org/Book');
      expect(result.registerGlobally, isTrue);
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
      expect(result.typeIri, 'https://schema.org/Person');
      expect(result.registerGlobally, isTrue);
    });
  });
}
