import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/iri_processor.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('IriProcessor', () {
    late LibraryElement2 libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('iri_processor_test_models.dart');
    });

    test('should process IriWithOnePart', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithOnePart')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithOnePart');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, 'http://example.org/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithOnePartExplicitlyGlobal', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(validationContext,
          libraryElement.getClass2('IriWithOnePartExplicitlyGlobal')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithOnePartExplicitlyGlobal');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, 'http://example.org/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithOnePartNamed', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithOnePartNamed')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithOnePartNamed');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, 'http://example.org/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithTwoParts', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithTwoParts')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithTwoParts');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, 'http://example.org/{type}/{value}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));
    });

    test('should process IriWithBaseUriAndTwoParts', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(validationContext,
          libraryElement.getClass2('IriWithBaseUriAndTwoParts')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithBaseUriAndTwoParts');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, '{+baseUri}/{type}/{value}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(2));
    });

    test('should process IriWithBaseUri', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithBaseUri')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithBaseUri');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, '{+baseUri}/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithBaseUriNoGlobal', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(validationContext,
          libraryElement.getClass2('IriWithBaseUriNoGlobal')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithBaseUriNoGlobal');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.mapper, isNull);
      expect(annotation.template, '{+baseUri}/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithNamedMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithNamedMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithNamedMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, 'testIriMapper');
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.template, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(annotation.mapper!.type!.type!.getDisplayString(), 'Type');
      expect(annotation.mapper!.type!.toTypeValue()!.getDisplayString(),
          'TestIriMapper');
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.template, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });

    test('should process IriWithMapperInstance', () {
      // Act
      final validationContext = ValidationContext();
      final result = IriProcessor.processClass(validationContext,
          libraryElement.getClass2('IriWithMapperInstance')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithMapperInstance');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestIriMapper2');
      expect(annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(annotation.template, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
  });
}
