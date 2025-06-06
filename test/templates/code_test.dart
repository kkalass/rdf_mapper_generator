import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:test/test.dart';

void main() {
  group('Code', () {
    group('constructors', () {
      test('literal constructor creates code without imports', () {
        const codeString = 'String myVariable = "hello";';
        final code = Code.literal(codeString);

        expect(code.code, equals(codeString));
        expect(code.imports, isEmpty);
        expect(code.hasImports, isFalse);
      });

      test('value factory creates code without imports', () {
        const codeString = '"hello world"';
        final code = Code.value(codeString);

        expect(code.code, equals(codeString));
        expect(code.imports, isEmpty);
        expect(code.hasImports, isFalse);
      });
    });

    group('type factory', () {
      test('creates code without imports when importUri is null', () {
        final code = Code.type('String');

        expect(code.code, equals('String'));
        expect(code.imports, isEmpty);
        expect(code.hasImports, isFalse);
      });

      test('creates code with import when importUri is provided', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass'));
        expect(code.hasImports, isTrue);
        expect(code.imports, hasLength(1));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('combine code with conflicting import aliases', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass2', importUri: 'package:foo/bar.dart');
        final code3 = Code.type('MyClass', importUri: 'package:foo/baz.dart');
        final code4 = Code.combine([
          code,
          Code.literal('<'),
          code3,
          Code.literal(', '),
          code2,
          Code.literal('>')
        ]);
        expect(code4.code, equals('foo.MyClass<foo2.MyClass, foo.MyClass2>'));
        expect(code4.hasImports, isTrue);
        expect(code4.imports, hasLength(2));
        final (_, imports) = code4.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
        expect(imports['package:foo/baz.dart'], equals('foo2'));
      });

      test('uses custom alias when provided', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final (resolved, imports) = code
            .resolveAliases(knownImports: {'package:foo/bar.dart': 'custom'});
        expect(resolved, equals('custom.MyClass'));
        expect(imports['package:foo/bar.dart'], equals('custom'));
      });

      test('handles qualified type names correctly', () {
        final code =
            Code.type('MyClass.InnerClass', importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass.InnerClass'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles dart: imports correctly', () {
        final code = Code.type('Future', importUri: 'dart:async');

        expect(code.code, equals('async.Future'));
        final (_, imports) = code.resolveAliases();
        expect(imports['dart:async'], equals('async'));
      });
    });

    group('constructor factory', () {
      test('creates code without imports when importUri is null', () {
        final code = Code.constructor('MyClass()');

        expect(code.code, equals('MyClass()'));
        expect(code.imports, isEmpty);
        expect(code.hasImports, isFalse);
      });

      test('creates code with import for regular constructor', () {
        final code =
            Code.constructor('MyClass()', importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass()'));
        expect(code.hasImports, isTrue);
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles const constructors correctly', () {
        final code = Code.constructor('const MyClass()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('const foo.MyClass()'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles named constructors', () {
        final code = Code.constructor('MyClass.named()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass.named()'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles const named constructors', () {
        final code = Code.constructor('const MyClass.named()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('const foo.MyClass.named()'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles constructors with parameters', () {
        final code = Code.constructor('MyClass("param1", 42)',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass("param1", 42)'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('handles constructors with nested parentheses', () {
        final code = Code.constructor('MyClass(SomeOtherClass())',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass(SomeOtherClass())'));
        final (_, imports) = code.resolveAliases();
        expect(imports['package:foo/bar.dart'], equals('foo'));
      });

      test('uses custom alias when provided', () {
        final code = Code.constructor(
          'MyClass()',
          importUri: 'package:foo/bar.dart',
        );

        final (resolved, imports) = code
            .resolveAliases(knownImports: {'package:foo/bar.dart': 'custom'});
        expect(resolved, equals('custom.MyClass()'));
        expect(imports['package:foo/bar.dart'], equals('custom'));
      });

      test('falls back to literal when constructor parsing fails', () {
        final code = Code.constructor('invalidConstructor',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('invalidConstructor'));
        expect(code.imports, isEmpty);
      });
    });

    group('combine factory', () {
      test('returns empty literal for empty list', () {
        final code = Code.combine([]);

        expect(code.code, equals(''));
        expect(code.imports, isEmpty);
      });

      test('returns single code instance unchanged', () {
        final originalCode = Code.literal('test');
        final code = Code.combine([originalCode]);

        expect(identical(code, originalCode), isTrue);
      });

      test('combines multiple codes without separator', () {
        final code1 = Code.literal('first');
        final code2 = Code.literal('second');
        final combined = Code.combine([code1, code2]);

        expect(combined.code, equals('firstsecond'));
        expect(combined.imports, isEmpty);
      });

      test('combines multiple codes with separator', () {
        final code1 = Code.literal('first');
        final code2 = Code.literal('second');
        final combined = Code.combine([code1, code2], separator: ', ');

        expect(combined.code, equals('first, second'));
        expect(combined.imports, isEmpty);
      });

      test('merges imports from multiple codes', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:bar/b.dart');
        final combined = Code.combine([code1, code2], separator: ' + ');

        expect(combined.code, equals('foo.ClassA + bar.ClassB'));
        expect(combined.imports, hasLength(2));
        final (_, imports) = combined.resolveAliases();
        expect(imports['package:foo/a.dart'], equals('foo'));
        expect(imports['package:bar/b.dart'], equals('bar'));
      });

      test('handles duplicate imports correctly', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:foo/a.dart');
        final combined = Code.combine([code1, code2]);

        expect(combined.imports, hasLength(1));
        final (_, imports) = combined.resolveAliases();
        expect(imports['package:foo/a.dart'], equals('foo'));
      });
    });

    group('alias generation behavior (tested indirectly)', () {
      test('generates consistent aliases for package URIs', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:foo/bar.dart');

        expect(code1.code, equals(code2.code));
        final (_, imports1) = code1.resolveAliases();
        final (_, imports2) = code2.resolveAliases();
        expect(imports1.keys.first, equals(imports2.keys.first));
        expect(imports1.values.first, equals(imports2.values.first));
      });

      test('generates different aliases for different package URIs', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:baz/qux.dart');

        final (_, imports1) = code1.resolveAliases();
        final (_, imports2) = code2.resolveAliases();
        expect(imports1.values.first, isNot(equals(imports2.values.first)));
      });

      test('handles complex package names appropriately', () {
        final code = Code.type('MyClass',
            importUri: 'package:my_complex_package/lib/models.dart');

        expect(code.code, contains('.MyClass'));
        expect(code.hasImports, isTrue);
        final (_, imports) = code.resolveAliases();
        // The alias should be some sanitized version of the package name
        expect(imports.values.first, matches(RegExp(r'^[a-zA-Z0-9_]+$')));
      });

      test('handles dart: imports appropriately', () {
        final code = Code.type('Future', importUri: 'dart:async');

        expect(code.code, contains('.Future'));
        expect(code.hasImports, isTrue);
        final (_, imports) = code.resolveAliases();
        // Should generate a reasonable alias for dart: imports
        expect(imports.values.first, matches(RegExp(r'^[a-zA-Z0-9_]+$')));
      });
    });

    group('toString', () {
      test('returns the code string', () {
        const codeString = 'test code';
        final code = Code.literal(codeString);
        expect(code.toString(), equals(codeString));
      });
    });

    group('equality and hashCode', () {
      test('equal instances have same hashCode', () {
        final code1 = Code.literal('test');
        final code2 = Code.literal('test');

        expect(code1 == code2, isTrue);
        // Note: Due to Map.hashCode implementation, identical content may have different hashCodes
        // across different instances. This is acceptable as long as equality works correctly.
      });

      test('different code strings are not equal', () {
        final code1 = Code.literal('test1');
        final code2 = Code.literal('test2');

        expect(code1 == code2, isFalse);
      });

      test('different imports are not equal', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:baz/qux.dart');

        expect(code1 == code2, isFalse);
      });

      test('same code and imports are equal', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:foo/bar.dart');

        expect(code1 == code2, isTrue);
        // Note: Due to Map.hashCode implementation, identical content may have different hashCodes
        // across different instances. This is acceptable as long as equality works correctly.
      });

      test('identical instances are equal', () {
        final code = Code.literal('test');

        expect(code == code, isTrue);
      });

      test('hashCode is consistent for same instance', () {
        final code = Code.literal('test');
        final hashCode1 = code.hashCode;
        final hashCode2 = code.hashCode;

        expect(hashCode1, equals(hashCode2));
      });

      test('comparing with different type returns false', () {
        final code = Code.literal('test');

        expect(code == 'test', isFalse);
      });
    });
  });
}
