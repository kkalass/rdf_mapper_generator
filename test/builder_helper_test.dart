import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:test/test.dart';

import 'test_helper.dart' as test_helper;

void main() {
  group('BuilderHelper', () {
    late LibraryElement2 globalResourceLibrary;
    late LibraryElement2 localResourceLibrary;
    late LibraryElement2 iriLibrary;
    late LibraryElement2 literalLibrary;
    late AssetReader assetReader;

    setUpAll(() async {
      assetReader = await PackageAssetReader.currentIsolate();

      // Initialize test environments for all test files
      final globalResult = await test_helper
          .analyzeTestFile('global_resource_processor_test_models.dart');
      globalResourceLibrary = globalResult.$1;

      final localResult = await test_helper
          .analyzeTestFile('local_resource_processor_test_models.dart');
      localResourceLibrary = localResult.$1;

      final iriResult =
          await test_helper.analyzeTestFile('iri_processor_test_models.dart');
      iriLibrary = iriResult.$1;

      final literalResult = await test_helper
          .analyzeTestFile('literal_processor_test_models.dart');
      literalLibrary = literalResult.$1;
    });

    group('Global Resource Mappers', () {
      test('should generate mapper for Book class', () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('Book')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class BookMapper'));
        expect(result, contains('implements GlobalResourceMapper<grptm.Book>'));
      });

      test('should generate mapper for class with empty IRI strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('ClassWithEmptyIriStrategy')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithEmptyIriStrategyMapper'));
      });

      test('should generate mapper for class with IRI template strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('ClassWithIriTemplateStrategy')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriTemplateStrategyMapper'));
      });

      test(
          'should generate mapper for class with IRI template strategy and context variable',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass2('ClassWithIriTemplateAndContextVariableStrategy')!
            ],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithIriTemplateAndContextVariableStrategy'));
      });

      test('should generate mapper for class with named IRI mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass2('ClassWithIriNamedMapperStrategy')!
            ],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriNamedMapperStrategyMapper'));
      });

      test('should generate mapper for class with IRI mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('ClassWithIriMapperStrategy')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriMapperStrategyMapper'));
      });

      test('should generate mapper for class with IRI mapper instance strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass2('ClassWithIriMapperInstanceStrategy')!
            ],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(
            result, contains('class ClassWithIriMapperInstanceStrategyMapper'));
      });

      test('should NOT generate mapper for class with named mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass2('ClassWithMapperNamedMapperStrategy')!
            ],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperNamedMapperStrategyMapper')));
      });

      test('should NOT generate mapper for class with mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('ClassWithMapperStrategy')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class ClassWithMapperStrategyMapper')));
      });

      test('should NOT generate mapper for class with mapper instance strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass2('ClassWithMapperInstanceStrategy')!
            ],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperInstanceStrategyMapper')));
      });

      test('should return null for non-annotated class', () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass2('NotAnnotated')!],
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNull);
      });
    });

    group('Local Resource Mappers', () {
      test('should generate mapper for Book class', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('Book')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class BookMapper'));
        expect(result, contains('implements LocalResourceMapper<lrptm.Book>'));
      });

      test('should generate mapper for ClassNoRegisterGlobally', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassNoRegisterGlobally')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassNoRegisterGloballyMapper'));
        expect(
            result,
            contains(
                'implements LocalResourceMapper<lrptm.ClassNoRegisterGlobally>'));
      });

      test('should generate mapper for ClassWithNoRdfType', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithNoRdfType')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithNoRdfTypeMapper'));
      });

      test('should generate mapper for ClassWithPositionalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithPositionalProperty')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithPositionalPropertyMapper'));
      });

      test('should generate mapper for ClassWithNonFinalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithNonFinalProperty')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithNonFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithNonFinalPropertyWithDefault',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass2('ClassWithNonFinalPropertyWithDefault')!
            ],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithNonFinalPropertyWithDefaultMapper'));
      });

      test('should generate mapper for ClassWithNonFinalOptionalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass2('ClassWithNonFinalOptionalProperty')!
            ],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(
            result, contains('class ClassWithNonFinalOptionalPropertyMapper'));
      });

      test('should generate mapper for ClassWithLateNonFinalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithLateNonFinalProperty')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithLateNonFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithLateFinalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithLateFinalProperty')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithLateFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithMixedFinalAndLateFinalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass2('ClassWithMixedFinalAndLateFinalProperty')!
            ],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithMixedFinalAndLateFinalPropertyMapper'));
      });

      test('should NOT generate mapper for ClassWithMapperNamedMapperStrategy',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass2('ClassWithMapperNamedMapperStrategy')!
            ],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperNamedMapperStrategyMapper')));
      });

      test('should NOT generate mapper for ClassWithMapperStrategy', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass2('ClassWithMapperStrategy')!],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class ClassWithMapperStrategyMapper')));
      });

      test('should NOT generate mapper for ClassWithMapperInstanceStrategy',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary.getClass2('ClassWithMapperInstanceStrategy')!
            ],
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperInstanceStrategyMapper')));
      });
    });

    group('IRI Mappers', () {
      test('should generate mapper for IriWithOnePart', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithOnePart')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartMapper'));
        expect(
            result, contains('implements IriTermMapper<iptm.IriWithOnePart>'));
      });

      test('should generate mapper for IriWithOnePartExplicitlyGlobal',
          () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithOnePartExplicitlyGlobal')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartExplicitlyGlobalMapper'));
      });

      test('should generate mapper for IriWithOnePartNamed', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithOnePartNamed')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartNamedMapper'));
      });

      test('should generate mapper for IriWithTwoParts', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithTwoParts')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithTwoPartsMapper'));
      });

      test('should generate mapper for IriWithBaseUriAndTwoParts', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithBaseUriAndTwoParts')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriAndTwoPartsMapper'));
      });

      test('should generate mapper for IriWithBaseUri', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithBaseUri')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriMapper'));
      });

      test('should generate mapper for IriWithBaseUriNoGlobal', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithBaseUriNoGlobal')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriNoGlobalMapper'));
      });

      test('should generate mapper for IriWithNonConstructorFields', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithNonConstructorFields')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithNonConstructorFieldsMapper'));
      });

      test(
          'should generate mapper for IriWithNonConstructorFieldsAndBaseUriNonGlobal',
          () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [
              iriLibrary
                  .getClass2('IriWithNonConstructorFieldsAndBaseUriNonGlobal')!
            ],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(
            result,
            contains(
                'class IriWithNonConstructorFieldsAndBaseUriNonGlobalMapper'));
      });

      test('should generate mapper for IriWithMixedFields', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithMixedFields')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithMixedFieldsMapper'));
      });

      test('should NOT generate mapper for IriWithNamedMapper', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithNamedMapper')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithNamedMapperMapper')));
      });

      test('should NOT generate mapper for IriWithMapper', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithMapper')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithMapperMapper')));
      });

      test('should NOT generate mapper for IriWithMapperInstance', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass2('IriWithMapperInstance')!],
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithMapperInstanceMapper')));
      });
    });

    group('Literal Mappers', () {
      test('should generate mapper for LiteralString', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralString')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralStringMapper'));
        expect(result,
            contains('implements LiteralTermMapper<lptm.LiteralString>'));
      });

      test('should generate mapper for Rating', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('Rating')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class RatingMapper'));
      });

      test('should generate mapper for LocalizedText', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LocalizedText')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LocalizedTextMapper'));
      });

      test('should generate mapper for LiteralDouble', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralDouble')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralDoubleMapper'));
      });

      test('should generate mapper for LiteralInteger', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralInteger')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralIntegerMapper'));
      });

      test('should generate mapper for Temperature with custom methods',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('Temperature')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class TemperatureMapper'));
        expect(result, contains('formatCelsius'));
        expect(result, contains('parse'));
      });

      test('should generate mapper for CustomLocalizedText', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('CustomLocalizedText')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class CustomLocalizedTextMapper'));
        expect(result, contains('toRdf'));
        expect(result, contains('fromRdf'));
      });

      test('should generate mapper for DoubleAsMilliunit', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('DoubleAsMilliunit')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class DoubleAsMilliunitMapper'));
        expect(result, contains('toMilliunit'));
        expect(result, contains('fromMilliunit'));
      });

      test('should generate mapper for LiteralWithNonConstructorValue',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralWithNonConstructorValue')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralWithNonConstructorValueMapper'));
      });

      test('should generate mapper for LocalizedTextWithNonConstructorLanguage',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [
              literalLibrary
                  .getClass2('LocalizedTextWithNonConstructorLanguage')!
            ],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class LocalizedTextWithNonConstructorLanguageMapper'));
      });

      test('should generate mapper for LiteralLateFinalLocalizedText',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralLateFinalLocalizedText')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralLateFinalLocalizedTextMapper'));
      });

      test('should NOT generate mapper for LiteralWithNamedMapper', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralWithNamedMapper')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class LiteralWithNamedMapperMapper')));
      });

      test('should NOT generate mapper for LiteralWithMapper', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralWithMapper')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class LiteralWithMapperMapper')));
      });

      test('should NOT generate mapper for LiteralWithMapperInstance',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass2('LiteralWithMapperInstance')!],
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(
            result, isNot(contains('class LiteralWithMapperInstanceMapper')));
      });
    });
  });
}
