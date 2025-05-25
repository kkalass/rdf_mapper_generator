import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late ClassElement2 bookClass;
  late ClassElement2 personClass;

  setUpAll(() async {
    final libraryElement = await analyzeTestFile('test_models.dart');
    bookClass = libraryElement.getClass2('Book')!;
    personClass = libraryElement.getClass2('Person')!;
  });

  group('PropertyProcessor', () {
    test('should process field with @RdfProperty annotation', () {
      // Find the title field in the Book class
      final titleField =
          bookClass.fields2.firstWhere((f) => f.name3 == 'title');

      // Act
      final result = PropertyProcessor.processField(titleField);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'title');
      expect(result.type, 'String');
      expect(result.propertyIri, 'https://schema.org/name');
      expect(result.isFinal, isTrue);
      expect(result.isRequired, isTrue);
    });

    test('should process field with @RdfProperty and IriMapping', () {
      // Find the authorId field in the Book class
      final authorField =
          bookClass.fields2.firstWhere((f) => f.name3 == 'authorId');

      // Act
      final result = PropertyProcessor.processField(authorField);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.type, 'String');
      expect(result.propertyIri, 'https://schema.org/author');
      expect(result.iriMapping, 'http://example.org/authors/{authorId}');
      expect(result.isFinal, isTrue);
      expect(result.isRequired, isTrue);
    });

    test('should return null for field without @RdfProperty annotation', () {
      // Find the id field in the Person class (has @RdfIriPart but not @RdfProperty)
      final idField = personClass.fields2.firstWhere((f) => f.name3 == 'id');

      // Act
      final result = PropertyProcessor.processField(idField);

      // Assert
      expect(result, isNull);
    });
  });
}
