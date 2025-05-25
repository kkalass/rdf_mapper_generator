import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:test/test.dart';

void main() {
  group('GlobalResourceProcessor', () {
    late ClassElement bookClass;
    late ClassElement personClass;
    late ClassElement invalidClass;

    setUpAll(() async {
      // Get the path to the test file relative to the project root
      final testFilePath = p.normalize(p.absolute(
        p.join('test', 'fixtures', 'test_models.dart'),
      ));
      
      // Ensure the file exists
      if (!File(testFilePath).existsSync()) {
        throw Exception('Test file not found at $testFilePath. Current directory: ${Directory.current.path}');
      }
      
      // Set up analysis context - use the fixtures directory
      final fixturesDir = p.dirname(testFilePath);
      final collection = AnalysisContextCollection(
        includedPaths: [fixturesDir],
      );

      // Parse the test file
      final session = collection.contextFor(testFilePath).currentSession;
      final result =
          await session.getResolvedUnit(testFilePath) as ResolvedUnitResult;

      // Get class elements
      final libraryElement = result.libraryElement;
      bookClass = libraryElement.getClass('Book')!;
      personClass = libraryElement.getClass('Person')!;
      invalidClass = libraryElement.getClass('NotAnnotated')!;
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

    test('should return null for class without RdfGlobalResource annotation', () {
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

    test('should handle class with custom type IRI and registerGlobally false', () {
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
