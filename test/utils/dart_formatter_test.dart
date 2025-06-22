import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/utils/dart_formatter.dart';

void main() {
  group('DartCodeFormatter', () {
    test('formats valid Dart code correctly', () {
      const unformattedCode = '''
class TestClass{
String   name;
int     age  ;
TestClass(this.name,this.age);
}
''';

      const expectedFormattedCode = '''class TestClass {
  String name;
  int age;
  TestClass(this.name, this.age);
}
''';

      final result = DartCodeFormatter.formatCode(unformattedCode);
      expect(result, equals(expectedFormattedCode));
    });

    test('handles invalid Dart code gracefully', () {
      const invalidCode = '''
class TestClass {
  String name
  // Missing semicolon above should cause parse error
}
''';

      // Should return the original code when formatting fails
      final result = DartCodeFormatter.formatCode(invalidCode);
      expect(result, equals(invalidCode));
    });

    test('formats complex generated mapper code', () {
      const complexCode = '''
/// Generated mapper for [Book] global resources.
class BookMapper implements GlobalResourceMapper<Book> {
final IriTerm typeIri = Schema.Book;
@override
Book fromRdfResource(IriTerm subject, DeserializationContext context) {
final reader = context.reader(subject);
final title = reader.require<String>(Schema.name);
final author = reader.optional<String>(Schema.author);
return Book(title: title, author: author);
}
}
''';

      final result = DartCodeFormatter.formatCode(complexCode);

      // Verify the result is properly formatted (contains proper indentation)
      expect(result, contains('  final IriTerm typeIri'));
      expect(result, contains('  @override'));
      expect(result, contains('    final reader'));
      expect(result.split('\n').length, greaterThan(1));
    });

    test('preserves comments and documentation', () {
      const codeWithComments = '''
/// This is a documentation comment
class TestClass {
// This is a regular comment
String name;
/* Multi-line
   comment */
int age;
}
''';

      final result = DartCodeFormatter.formatCode(codeWithComments);

      expect(result, contains('/// This is a documentation comment'));
      expect(result, contains('// This is a regular comment'));
      expect(result, contains('/* Multi-line'));
    });
  });
}
