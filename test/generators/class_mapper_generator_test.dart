import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/generators/class_mapper_generator.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('ClassMapperGenerator', () {
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      libraryElement =
          await analyzeTestFile('global_resource_processor_test_models.dart');
    });

    group('generateGlobalResourceMapper', () {
      test('should generate basic mapper class structure', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode,
            contains('import \'package:rdf_core/rdf_core.dart\';'));
        expect(generatedCode,
            contains('import \'package:rdf_mapper/rdf_mapper.dart\';'));
        expect(generatedCode,
            contains('class BookMapper implements GlobalResourceMapper<Book>'));
        expect(generatedCode,
            contains('/// Generated mapper for [Book] global resources.'));
      });

      test('should include typeIri field when classIri is provided', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode, contains('@override'));
        expect(generatedCode,
            contains('final IriTerm typeIri = SchemaBook.classIri'));
      });

      test('should generate fromRdfResource method stub', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode, contains('@override'));
        expect(
            generatedCode,
            contains(
                'Book fromRdfResource(IriTerm subject, DeserializationContext context)'));
        expect(generatedCode,
            contains('// TODO: Implement deserialization logic'));
        expect(
            generatedCode,
            contains(
                'throw UnimplementedError(\'Deserialization not yet implemented\')'));
      });

      test('should generate toRdfResource method stub', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode, contains('@override'));
        expect(
            generatedCode, contains('(IriTerm, List<Triple>) toRdfResource('));
        expect(generatedCode, contains('Book resource,'));
        expect(generatedCode, contains('SerializationContext context,'));
        expect(generatedCode, contains('RdfSubject? parentSubject,'));
        expect(
            generatedCode, contains('// TODO: Implement serialization logic'));
        expect(
            generatedCode,
            contains(
                'throw UnimplementedError(\'Serialization not yet implemented\')'));
      });

      test('should generate mapper for class without classIri', () {
        // Arrange
        final emptyClass =
            libraryElement.getClass2('ClassWithEmptyIriStrategy')!;
        final resourceInfo = GlobalResourceProcessor.processClass(emptyClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(
            generatedCode,
            contains(
                'class ClassWithEmptyIriStrategyMapper implements GlobalResourceMapper<ClassWithEmptyIriStrategy>'));
        expect(generatedCode,
            contains('final IriTerm typeIri = SchemaPerson.classIri'));
      });

      test('should generate proper class name for complex class names', () {
        // Arrange
        final complexClass =
            libraryElement.getClass2('ClassWithIriTemplateStrategy')!;
        final resourceInfo =
            GlobalResourceProcessor.processClass(complexClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode,
            contains('class ClassWithIriTemplateStrategyMapper'));
        expect(
            generatedCode,
            contains(
                'implements GlobalResourceMapper<ClassWithIriTemplateStrategy>'));
        expect(generatedCode,
            contains('ClassWithIriTemplateStrategy fromRdfResource'));
        expect(
            generatedCode, contains('ClassWithIriTemplateStrategy resource,'));
      });

      test('should generate valid Dart code structure', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        // Check that the generated code has proper structure
        expect(generatedCode, startsWith('import '));
        expect(generatedCode, contains('class '));
        expect(generatedCode, contains('{'));
        expect(generatedCode, endsWith('}'));

        // Check that all methods are properly closed
        final openBraces = '{'.allMatches(generatedCode).length;
        final closeBraces = '}'.allMatches(generatedCode).length;
        expect(openBraces, equals(closeBraces));
      });
    });

    group('_generateImports', () {
      test('should generate required import statements', () {
        // Arrange
        final bookClass = libraryElement.getClass2('Book')!;
        final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

        // Act
        final generatedCode =
            ClassMapperGenerator.generateGlobalResourceMapper(resourceInfo);

        // Assert
        expect(generatedCode,
            contains('import \'package:rdf_core/rdf_core.dart\';'));
        expect(generatedCode,
            contains('import \'package:rdf_mapper/rdf_mapper.dart\';'));
      });
    });
  });
}
