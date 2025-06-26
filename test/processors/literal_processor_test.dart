import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('LiteralProcessor', () {
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('literal_processor_test_models.dart');
    });

    test('should process LiteralString', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('LiteralString')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralString');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].isRdfLanguageTag, isFalse);
      expect(result.constructors[0].parameters[0].isIriPart, isFalse);
      expect(result.constructors[0].parameters[0].name, 'foo');
    });

    test('should process Rating', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('Rating')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.Rating');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].isRdfLanguageTag, isFalse);
      expect(result.constructors[0].parameters[0].name, 'stars');
    });

    test('should process LocalizedText with language tag', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('LocalizedText')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LocalizedText');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));
      expect(result.constructors[0].parameters, hasLength(2));

      // Check for RdfValue parameter
      final valueParam =
          result.constructors[0].parameters.firstWhere((p) => p.isRdfValue);
      expect(valueParam.name, 'text');
      expect(valueParam.isRdfLanguageTag, isFalse);

      // Check for RdfLanguageTag parameter
      final languageParam = result.constructors[0].parameters
          .firstWhere((p) => p.isRdfLanguageTag);
      expect(languageParam.name, 'language');
      expect(languageParam.isRdfValue, isFalse);
    });

    test('should process LiteralDouble with XSD datatype', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('LiteralDouble')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralDouble');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNotNull);
      expect(
          annotation.datatype!.code.resolveAliases(knownImports: {
            'package:rdf_vocabularies/src/generated/xsd.dart': ''
          }).$1,
          'Xsd.double');
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].name, 'foo');
    });

    test('should process LiteralInteger with XSD datatype', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('LiteralInteger')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralInteger');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNotNull);
      expect(
          annotation.datatype!.code.resolveAliases(knownImports: {
            'package:rdf_vocabularies/src/generated/xsd.dart': ''
          }).$1,
          'Xsd.integer');
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process Temperature with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('Temperature')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.Temperature');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, 'formatCelsius');
      expect(annotation.fromLiteralTermMethod, 'parse');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'celsius');
    });

    test('should process CustomLocalizedText with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('CustomLocalizedText')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.CustomLocalizedText');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, 'toRdf');
      expect(annotation.fromLiteralTermMethod, 'fromRdf');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));
      expect(result.constructors[0].parameters, hasLength(2));
      expect(result.constructors[0].parameters[0].name, 'text');
      expect(result.constructors[0].parameters[1].name, 'language');
    });

    test('should process DoubleAsMilliunit with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('DoubleAsMilliunit')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.DoubleAsMilliunit');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, 'toMilliunit');
      expect(annotation.fromLiteralTermMethod, 'fromMilliunit');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithNamedMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(validationContext,
          libraryElement.getClass2('LiteralWithNamedMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithNamedMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, 'testLiteralMapper');
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass2('LiteralWithMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(
          annotation.mapper!.type!.name.codeWithoutAlias, 'TestLiteralMapper');
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithMapperInstance', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(validationContext,
          libraryElement.getClass2('LiteralWithMapperInstance')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithMapperInstance');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestLiteralMapper2');
      expect(annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });
  });
}
