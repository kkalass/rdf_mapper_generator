import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:test/test.dart';

void main() {
  late ClassElement bookClass;
  late ClassElement personClass;

  setUpAll(() async {
    // Set up the analysis context with absolute paths
    final fixturesPath = p.join(p.current, 'test', 'fixtures');
    final testModelsPath = p.join(fixturesPath, 'test_models.dart');
    
    final collection = AnalysisContextCollection(
      includedPaths: [p.absolute(fixturesPath)],
    );

    // Get the test file
    final context = collection.contextFor(p.absolute(testModelsPath));
    final result = await context.currentSession.getResolvedUnit(
      p.absolute(testModelsPath),
    ) as ResolvedUnitResult;

    // Find the test classes in the library's top-level elements
    for (final element in result.libraryElement.topLevelElements) {
      if (element is ClassElement) {
        if (element.name == 'Book') {
          bookClass = element;
        } else if (element.name == 'Person') {
          personClass = element;
        }
      }
    }
  });

  group('PropertyProcessor', () {
    test('should process field with @RdfProperty annotation', () {
      // Find the title field in the Book class
      final titleField = bookClass.fields.firstWhere((f) => f.name == 'title');
      
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
      final authorField = bookClass.fields.firstWhere((f) => f.name == 'authorId');
      
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
      final idField = personClass.fields.firstWhere((f) => f.name == 'id');
      
      // Act
      final result = PropertyProcessor.processField(idField);
      
      // Assert
      expect(result, isNull);
    });
  });
}
