import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/libs_by_classname.dart';
import 'package:test/test.dart';
import 'test_helper.dart' as test_helper;

void main() {
  group('BuilderHelper', () {
    late LibsByClassName libsByClassName;
    late LibraryElement2 library;
    late AssetReader assetReader;

    setUpAll(() async {
      assetReader = await PackageAssetReader.currentIsolate();
      // Initialize test environment
      final result = await test_helper
          .analyzeTestFile('global_resource_processor_test_models.dart');
      library = result.$1;
      libsByClassName = LibsByClassName.create(library);
    });

    test('should generate mapper for Book class', () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('Book')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class BookMapper'));
      expect(result, contains('implements GlobalResourceMapper<Book>'));
    });

    test('should generate mapper for class with empty IRI strategy', () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithEmptyIriStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithEmptyIriStrategyMapper'));
    });

    test('should generate mapper for class with IRI template strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithIriTemplateStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriTemplateStrategyMapper'));
    });

    test('should generate mapper for class with named IRI mapper strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithIriNamedMapperStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriNamedMapperStrategyMapper'));
    });

    test('should generate mapper for class with IRI mapper strategy', () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithIriMapperStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithIriMapperStrategyMapper'));
    });

    test('should generate mapper for class with IRI mapper instance strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithIriMapperInstanceStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(
          result, contains('class ClassWithIriMapperInstanceStrategyMapper'));
    });

    test('should generate mapper for class with named mapper strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithMapperNamedMapperStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(
          result, contains('class ClassWithMapperNamedMapperStrategyMapper'));
    });

    test('should generate mapper for class with mapper strategy', () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithMapperStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithMapperStrategyMapper'));
    });

    test('should generate mapper for class with mapper instance strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('ClassWithMapperInstanceStrategy')!],
          libsByClassName,
          assetReader);
      expect(result, isNotNull);
      expect(result, contains('class ClassWithMapperInstanceStrategyMapper'));
    });

    test('should return null for non-annotated class', () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [library.getClass2('NotAnnotated')!],
          libsByClassName,
          assetReader);
      expect(result, isNull);
    });
  });
}
