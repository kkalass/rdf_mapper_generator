import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
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
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass2('IriWithOnePart')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'iptm.IriWithOnePart');
      var annotation = result.annotation as RdfIriInfo;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.template, 'http://example.org/books/{isbn}');

      expect(result.constructors, hasLength(1));
      expect(result.fields, hasLength(1));
    });
  });
}
