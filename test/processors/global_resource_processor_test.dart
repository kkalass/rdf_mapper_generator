import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:analyzer/dart/element/element.dart';
// build.dart is not directly used in this test file for now,
// but Resolver comes from it and might be needed for more complex tests.
// import 'package:build/build.dart';

Future<void> main() async {
  // Initial setup for source_gen_test
  // This path should point to the root of the package being tested.
  // Adjust if your test file is structured differently.
  final reader = await initializeLibraryReaderForDirectory(
    '.', // Assuming tests are run from the package root
    'global_resource_processor_test_input.dart', // A dummy file, content will be provided per test
  );

  // Helper function to get ClassElement
  ClassElement getClassElement(LibraryReader libraryReader, String className) {
    final element = libraryReader.allElements.whereType<ClassElement>().firstWhere(
          (e) => e.name == className,
          orElse: () => throw Exception('Class $className not found'),
        );
    return element;
  }

  group('GlobalResourceProcessor Tests', () {
    // Test 1: Class with @RdfGlobalResource annotation
    test('processes class with @RdfGlobalResource annotation', () async {
      final testSource = '''
        import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

        @RdfGlobalResource(null, IriStrategy('test'))
        class TestClass1 {
          String name;
          int age;

          TestClass1(this.name, this.age);

          TestClass1.named(String value) : name = value, age = 0;

          // Static field, should be ignored
          static String staticField = 'ignore_me';

          // Private field, should be ignored
          String _privateField = 'ignore_me_too';

          // Factory constructor, should be ignored
          factory TestClass1.factory() { return TestClass1('factory', 100); }
        }
      ''';
      
      final library = await resolveSource(
        testSource,
        (resolver) => resolver.findLibraryByName(''), // Finds the current unnamed library
        tearDown: (_) {}, // No specific teardown needed for this simple case
      );
      final classElement = getClassElement(LibraryReader(library), 'TestClass1');
      final processor = GlobalResourceProcessor(classElement, null); // Resolver might not be needed for current tests
      final result = processor.process();

      expect(result, isNotNull);
      expect(result?.className, 'TestClass1');
      
      expect(result?.fields.length, 2);
      expect(result?.fields.any((f) => f['name'] == 'name' && f['type'] == 'String'), isTrue);
      expect(result?.fields.any((f) => f['name'] == 'age' && f['type'] == 'int'), isTrue);
      
      expect(result?.constructors.length, 2); 
      // Default constructor
      final defaultConstructor = result?.constructors.firstWhere((c) => c['name'] == '', orElse: () => {});
      expect(defaultConstructor, isNotNull);
      expect(defaultConstructor?['parameters'].length, 2);
      expect(defaultConstructor?['parameters'].any((p) => p['name'] == 'name' && p['type'] == 'String'), isTrue);
      expect(defaultConstructor?['parameters'].any((p) => p['name'] == 'age' && p['type'] == 'int'), isTrue);

      // Named constructor
      final namedConstructor = result?.constructors.firstWhere((c) => c['name'] == 'named', orElse: () => {});
      expect(namedConstructor, isNotNull);
      expect(namedConstructor?['parameters'].length, 1);
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'value' && p['type'] == 'String'), isTrue);
    });

    // Test 2: Class without @RdfGlobalResource annotation
    test('returns null for class without @RdfGlobalResource annotation', () async {
      final testSource = '''
        class TestClass2 {
          String data;
          TestClass2(this.data);
        }
      ''';
      final library = await resolveSource(testSource, (resolver) => resolver.findLibraryByName(''));
      final classElement = getClassElement(LibraryReader(library), 'TestClass2');
      final processor = GlobalResourceProcessor(classElement, null);
      final result = processor.process();

      expect(result, isNull);
    });

    // Test 3: Class with annotation but no explicit fields/constructors
    test('processes annotated class with empty body', () async {
      final testSource = '''
        import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

        @RdfGlobalResource(null, IriStrategy('test3'))
        class TestClass3 {}
      ''';
      final library = await resolveSource(testSource, (resolver) => resolver.findLibraryByName(''));
      final classElement = getClassElement(LibraryReader(library), 'TestClass3');
      final processor = GlobalResourceProcessor(classElement, null);
      final result = processor.process();

      expect(result, isNotNull);
      expect(result?.className, 'TestClass3');
      expect(result?.fields, isEmpty);
      expect(result?.constructors.length, 1); // Default constructor
      expect(result?.constructors.first['name'], '');
      expect(result?.constructors.first['parameters'], isEmpty);
    });

    // Test 4: Class with multiple constructors (covered by Test 1 already, but can be more specific)
    test('processes annotated class with multiple constructors', () async {
      final testSource = '''
        import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

        @RdfGlobalResource(null, IriStrategy('test4'))
        class TestClass4 {
          String id;
          String? data;

          TestClass4(this.id);
          TestClass4.named(this.id, this.data);
          TestClass4.optional(this.id, [this.data]);
        }
      ''';
      final library = await resolveSource(testSource, (resolver) => resolver.findLibraryByName(''));
      final classElement = getClassElement(LibraryReader(library), 'TestClass4');
      final processor = GlobalResourceProcessor(classElement, null);
      final result = processor.process();

      expect(result, isNotNull);
      expect(result?.className, 'TestClass4');
      expect(result?.fields.length, 2);
      expect(result?.fields.any((f) => f['name'] == 'id' && f['type'] == 'String'), isTrue);
      expect(result?.fields.any((f) => f['name'] == 'data' && f['type'] == 'String?'), isTrue);
      
      expect(result?.constructors.length, 3);

      final defaultConstructor = result?.constructors.firstWhere((c) => c['name'] == '', orElse: () => {});
      expect(defaultConstructor?['parameters'].length, 1);
      expect(defaultConstructor?['parameters'].first['name'], 'id');
      expect(defaultConstructor?['parameters'].first['type'], 'String');

      final namedConstructor = result?.constructors.firstWhere((c) => c['name'] == 'named', orElse: () => {});
      expect(namedConstructor?['parameters'].length, 2);
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'id' && p['type'] == 'String'), isTrue);
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'data' && p['type'] == 'String?'), isTrue);
      
      final optionalConstructor = result?.constructors.firstWhere((c) => c['name'] == 'optional', orElse: () => {});
      expect(optionalConstructor?['parameters'].length, 2);
      expect(optionalConstructor?['parameters'].any((p) => p['name'] == 'id' && p['type'] == 'String'), isTrue);
      expect(optionalConstructor?['parameters'].any((p) => p['name'] == 'data' && p['type'] == 'String?'), isTrue); // Optional parameters still have their type
    });
  });
}

// Helper to use source_gen_test's resolveSource without needing a file on disk
// The `resolver` function provided to `resolveSource` will give us a Resolver instance.
// We then use this resolver to find the library we just parsed from the source string.
// For simple cases, finding the library by an empty name `''` often works for the current "in-memory" library.
// The `tearDown` parameter is for cleaning up, not strictly needed here.
Future<LibraryElement> resolveSource(
  String source,
  Future<LibraryElement?> Function(Resolver) resolve, {
  Future<void> Function(LibraryElement)? tearDown,
}) async {
  final testAssetId = AssetId('test_package', 'lib/test_library.dart');
  return await resolveAsset(
    AssetReader.fromString(source, testAssetId),
    testAssetId,
    resolve,
    tearDown: tearDown,
  );
}
