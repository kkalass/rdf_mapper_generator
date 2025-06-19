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
  });
}
