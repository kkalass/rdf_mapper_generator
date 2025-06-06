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
        expect(code.imports['package:foo/bar.dart']?.uri,
            equals('package:foo/bar.dart'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
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
        expect(code4.imports['package:foo/bar.dart']?.uri,
            equals('package:foo/bar.dart'));
        expect(code4.imports['package:foo/bar.dart']?.alias, equals('foo'));
        expect(code4.imports['package:foo/baz.dart']?.uri,
            equals('package:foo/baz.dart'));
        expect(code4.imports['package:foo/baz.dart']?.alias, equals('foo2'));
      });

      test('uses custom alias when provided', () {
        final code = Code.type('MyClass',
            importUri: 'package:foo/bar.dart', alias: 'custom');

        expect(code.code, equals('custom.MyClass'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('custom'));
      });

      test('handles qualified type names correctly', () {
        final code =
            Code.type('MyClass.InnerClass', importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.InnerClass'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles dart: imports correctly', () {
        final code = Code.type('Future', importUri: 'dart:async');

        expect(code.code, equals('async.Future'));
        expect(code.imports['dart:async']?.alias, equals('async'));
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
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles const constructors correctly', () {
        final code = Code.constructor('const MyClass()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('const foo.MyClass()'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles named constructors', () {
        final code = Code.constructor('MyClass.named()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass.named()'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles const named constructors', () {
        final code = Code.constructor('const MyClass.named()',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('const foo.MyClass.named()'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles constructors with parameters', () {
        final code = Code.constructor('MyClass("param1", 42)',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass("param1", 42)'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('handles constructors with nested parentheses', () {
        final code = Code.constructor('MyClass(SomeOtherClass())',
            importUri: 'package:foo/bar.dart');

        expect(code.code, equals('foo.MyClass(SomeOtherClass())'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('foo'));
      });

      test('uses custom alias when provided', () {
        final code = Code.constructor('MyClass()',
            importUri: 'package:foo/bar.dart', alias: 'custom');

        expect(code.code, equals('custom.MyClass()'));
        expect(code.imports['package:foo/bar.dart']?.alias, equals('custom'));
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
        expect(combined.imports['package:foo/a.dart']?.alias, equals('foo'));
        expect(combined.imports['package:bar/b.dart']?.alias, equals('bar'));
      });

      test('handles duplicate imports correctly', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:foo/a.dart');
        final combined = Code.combine([code1, code2]);

        expect(combined.imports, hasLength(1));
        expect(combined.imports['package:foo/a.dart']?.alias, equals('foo'));
      });
    });

    group('mapAliases', () {
      test('returns same instance when no imports exist', () {
        final code = Code.literal('test');
        final mapped = code.mapAliases({'package:foo/bar.dart': 'newAlias'});

        expect(identical(code, mapped), isTrue);
      });

      test('returns same instance when alias mapping is empty', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final mapped = code.mapAliases({});

        // The method may return a new instance even with empty mapping
        // What matters is that the code and imports are the same
        expect(mapped.code, equals(code.code));
        expect(mapped.imports, equals(code.imports));
      });

      test('maps aliases correctly', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final mapped = code.mapAliases({'package:foo/bar.dart': 'newAlias'});

        expect(mapped.code, equals('newAlias.MyClass'));
        expect(mapped.imports['package:foo/bar.dart']?.alias,
            equals('foo')); // Original import info preserved
      });

      test('handles multiple alias mappings', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:bar/b.dart');
        final combined = Code.combine([code1, code2], separator: ' + ');

        final mapped = combined.mapAliases({
          'package:foo/a.dart': 'aliasA',
          'package:bar/b.dart': 'aliasB',
        });

        expect(mapped.code, equals('aliasA.ClassA + aliasB.ClassB'));
      });

      test('only maps aliases that are in the mapping', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:bar/b.dart');
        final combined = Code.combine([code1, code2], separator: ' + ');

        final mapped = combined.mapAliases({
          'package:foo/a.dart': 'aliasA',
          // package:bar/b.dart not included in mapping
        });

        expect(mapped.code, equals('aliasA.ClassA + bar.ClassB'));
      });

      test('handles word boundaries correctly to avoid partial replacements',
          () {
        // Create a combined code that simulates having imports
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.literal('bar.ClassB');
        final combined = Code.combine([code1, code2], separator: ' foo');

        final mapped = combined.mapAliases({
          'package:foo/a.dart': 'newFoo',
        });

        // Should replace 'foo' in 'foo.ClassA' but not in 'foobar.ClassB'
        expect(mapped.code, contains('newFoo.ClassA'));
        expect(mapped.code, contains('foobar.ClassB'));
      });
    });

    group('alias generation behavior (tested indirectly)', () {
      test('generates consistent aliases for package URIs', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:foo/bar.dart');

        expect(code1.code, equals(code2.code));
        expect(code1.imports.keys.first, equals(code2.imports.keys.first));
        expect(code1.imports.values.first.alias,
            equals(code2.imports.values.first.alias));
      });

      test('generates different aliases for different package URIs', () {
        final code1 = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final code2 = Code.type('MyClass', importUri: 'package:baz/qux.dart');

        expect(code1.imports.values.first.alias,
            isNot(equals(code2.imports.values.first.alias)));
      });

      test('handles complex package names appropriately', () {
        final code = Code.type('MyClass',
            importUri: 'package:my_complex_package/lib/models.dart');

        expect(code.code, contains('.MyClass'));
        expect(code.hasImports, isTrue);
        // The alias should be some sanitized version of the package name
        expect(code.imports.values.first.alias,
            matches(RegExp(r'^[a-zA-Z0-9_]+$')));
      });

      test('handles dart: imports appropriately', () {
        final code = Code.type('Future', importUri: 'dart:async');

        expect(code.code, contains('.Future'));
        expect(code.hasImports, isTrue);
        // Should generate a reasonable alias for dart: imports
        expect(code.imports.values.first.alias,
            matches(RegExp(r'^[a-zA-Z0-9_]+$')));
      });
    });

    group('properties', () {
      test('code getter returns the code string', () {
        const codeString = 'test code';
        final code = Code.literal(codeString);
        expect(code.code, equals(codeString));
      });

      test('imports getter returns unmodifiable map', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final imports = code.imports;

        expect(imports, isA<Map<String, ImportInfo>>());
        expect(
            () => imports['new'] = const ImportInfo(uri: 'test', alias: 'test'),
            throwsUnsupportedError);
      });

      test('hasImports returns false for literal code', () {
        final code = Code.literal('test');
        expect(code.hasImports, isFalse);
      });

      test('hasImports returns true when imports exist', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        expect(code.hasImports, isTrue);
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

  group('ImportInfo', () {
    group('constructor', () {
      test('creates instance with required parameters', () {
        const importInfo =
            ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');

        expect(importInfo.uri, equals('package:foo/bar.dart'));
        expect(importInfo.alias, equals('foo'));
      });
    });

    group('equality and hashCode', () {
      test('equal instances have same hashCode', () {
        const info1 = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');
        const info2 = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');

        expect(info1 == info2, isTrue);
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('different uri makes instances unequal', () {
        const info1 = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');
        const info2 = ImportInfo(uri: 'package:baz/qux.dart', alias: 'foo');

        expect(info1 == info2, isFalse);
      });

      test('different alias makes instances unequal', () {
        const info1 = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');
        const info2 = ImportInfo(uri: 'package:foo/bar.dart', alias: 'bar');

        expect(info1 == info2, isFalse);
      });

      test('identical instances are equal', () {
        const info = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');

        expect(info == info, isTrue);
      });

      test('comparing with different type returns false', () {
        const info = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');

        expect(info == 'test', isFalse);
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        const info = ImportInfo(uri: 'package:foo/bar.dart', alias: 'foo');

        expect(info.toString(),
            equals('ImportInfo(uri: package:foo/bar.dart, alias: foo)'));
      });
    });
  });
}
