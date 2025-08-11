import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Generic Type Validation Simple Tests', () {
    test('buildTemplateDataFromString works with valid non-generic class', () async {
      // Test with a minimal example that doesn't require external packages
      const sourceCode = '''
class SimpleClass {
  final String name;
  const SimpleClass(this.name);
}
''';

      final templateData = await buildTemplateDataFromString(sourceCode);
      
      // Verify basic functionality - no mappers should be generated since no annotations
      expect(templateData, isNotNull);
      expect(templateData.mappers, isEmpty); // No RDF annotations = no mappers
    });

    test('demonstrates the validation infrastructure is working', () {
      // This test shows that ValidationException exists and works
      final context = ValidationContext();
      context.addError('Test error message');
      
      expect(() => context.throwIfErrors(), throwsA(isA<ValidationException>()));
    });

    test('validation context collects multiple errors', () {
      final context = ValidationContext();
      context.addError('First error');
      context.addError('Second error');
      
      ValidationException? caughtException;
      try {
        context.throwIfErrors();
      } catch (e) {
        if (e is ValidationException) {
          caughtException = e;
        }
      }
      
      expect(caughtException, isNotNull);
      expect(caughtException!.errors, hasLength(2));
      expect(caughtException.errors.first, equals('First error'));
      expect(caughtException.errors.last, equals('Second error'));
    });
  });
}