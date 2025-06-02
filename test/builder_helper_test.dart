import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';
import 'package:test/test.dart';

void main() {
  group('BuilderHelper', () {
    late LibsByClassName libsByClassName;
    late ClassElement2 bookClass;
    late ClassElement2 classWithEmptyIriStrategy;
    late ClassElement2 classWithIriTemplateStrategy;
    late ClassElement2 classWithIriNamedMapperStrategy;
    late ClassElement2 classWithIriMapperStrategy;
    late ClassElement2 classWithIriMapperInstanceStrategy;
    late ClassElement2 classWithMapperNamedMapperStrategy;
    late ClassElement2 classWithMapperStrategy;
    late ClassElement2 classWithMapperInstanceStrategy;
    late ClassElement2 notAnnotatedClass;

    setUpAll(() async {
      // Initialize test environment
      final library = await _resolveTestLibrary();
      libsByClassName = LibsByClassName.create(library);

      // Get class elements from the test library
      bookClass = library.getClass2('Book')!;
      classWithEmptyIriStrategy =
          library.getClass2('ClassWithEmptyIriStrategy')!;
      classWithIriTemplateStrategy =
          library.getClass2('ClassWithIriTemplateStrategy')!;
      classWithIriNamedMapperStrategy =
          library.getClass2('ClassWithIriNamedMapperStrategy')!;
      classWithIriMapperStrategy =
          library.getClass2('ClassWithIriMapperStrategy')!;
      classWithIriMapperInstanceStrategy =
          library.getClass2('ClassWithIriMapperInstanceStrategy')!;
      classWithMapperNamedMapperStrategy =
          library.getClass2('ClassWithMapperNamedMapperStrategy')!;
      classWithMapperStrategy = library.getClass2('ClassWithMapperStrategy')!;
      classWithMapperInstanceStrategy =
          library.getClass2('ClassWithMapperInstanceStrategy')!;
      notAnnotatedClass = library.getClass2('NotAnnotated')!;
    });

    test('should generate mapper for Book class', () {
      final result = BuilderHelper().build(bookClass, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class BookMapper'));
      expect(result, contains('implements GlobalResourceMapper<Book>'));
    });

    test('should generate mapper for class with empty IRI strategy', () {
      final result =
          BuilderHelper().build(classWithEmptyIriStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithEmptyIriStrategyMapper'));
    });

    test('should generate mapper for class with IRI template strategy', () {
      final result =
          BuilderHelper().build(classWithIriTemplateStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriTemplateStrategyMapper'));
    });

    test('should generate mapper for class with named IRI mapper strategy', () {
      final result = BuilderHelper()
          .build(classWithIriNamedMapperStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriNamedMapperStrategyMapper'));
    });

    test('should generate mapper for class with IRI mapper strategy', () {
      final result =
          BuilderHelper().build(classWithIriMapperStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriMapperStrategyMapper'));
    });

    test('should generate mapper for class with IRI mapper instance strategy',
        () {
      final result = BuilderHelper()
          .build(classWithIriMapperInstanceStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(
          result, contains('class ClassWithIriMapperInstanceStrategyMapper'));
    });

    test('should generate mapper for class with named mapper strategy', () {
      final result = BuilderHelper()
          .build(classWithMapperNamedMapperStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(
          result, contains('class ClassWithMapperNamedMapperStrategyMapper'));
    });

    test('should generate mapper for class with mapper strategy', () {
      final result =
          BuilderHelper().build(classWithMapperStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithMapperStrategyMapper'));
    });

    test('should generate mapper for class with mapper instance strategy', () {
      final result = BuilderHelper()
          .build(classWithMapperInstanceStrategy, libsByClassName);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithMapperInstanceStrategyMapper'));
    });

    test('should return null for non-annotated class', () {
      final result = BuilderHelper().build(notAnnotatedClass, libsByClassName);
      expect(result, isNull);
    });
  });
}

Future<LibraryElement2> _resolveTestLibrary() async {
  // This is a simplified version - in a real test, you'd use the analyzer package
  // to parse and resolve the test models file
  throw UnimplementedError('Implement test library resolution');
}
