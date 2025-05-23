// Imports for new model (element2) for test logic
import 'package:analyzer/dart/element/element2.dart';
// Imports for old model (element) for MockResolver's interface compatibility
import 'package:analyzer/dart/element/element.dart' as old_model; 
import 'package:analyzer/dart/ast/ast.dart'; // For AstNode, CompilationUnit
import 'package:build/build.dart'; // For Resolver, AssetId, AssetReader
import 'package:glob/glob.dart'; // For Glob
import 'package:source_gen_test/source_gen_test.dart'; // For resolveSources
import 'package:test/test.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';

// MockResolver for testing - implements Resolver with old model types where interface expects them
class MockResolver implements Resolver {
  // Removing @override for methods that had "override_on_non_overriding_member" warnings.
  Future<AssetReader> assetReader(AssetId assetId) async => throw UnimplementedError('assetReader not implemented');

  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError('findAssets not implemented');

  Future<bool> isReadable(AssetId assetId) async => throw UnimplementedError('isReadable not implemented');

  // Keeping @override for methods that were NOT flagged by recent analyzer output for this warning
  @override
  Future<old_model.LibraryElement> libraryFor(AssetId assetId, {bool allowSyntaxErrors = false}) async => throw UnimplementedError('libraryFor not implemented');
  
  Future<List<old_model.LibraryElement>> findLibraries(Glob glob) async => throw UnimplementedError('findLibraries not implemented');

  Future<old_model.LibraryElement> loadLibrary(AssetId assetId) async => throw UnimplementedError('loadLibrary not implemented');

  Future<AssetId> resolveAsset(Uri uri, {AssetId? from}) async => throw UnimplementedError('resolveAsset not implemented');

  @override
  Future<old_model.LibraryElement?> findLibraryByName(String libraryName) async => throw UnimplementedError('findLibraryByName not implemented');

  @override
  Future<bool> isLibrary(AssetId assetId) async => throw UnimplementedError('isLibrary not implemented');

  @override
  Stream<old_model.LibraryElement> get libraries => throw UnimplementedError('libraries not implemented');

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId, {bool allowSyntaxErrors = false}) async => throw UnimplementedError('compilationUnitFor not implemented');

  // Ensured ElementDeclaration is from old_model. @override already removed.
  Future<old_model.Element?> findElement(old_model.ElementDeclaration declaration) async => throw UnimplementedError('findElement not implemented.');
  
  // @override already removed.
  Future<AstNode?> astNodeFor(old_model.Element element, {bool resolve = false}) async => throw UnimplementedError('astNodeFor not implemented');
  
  // @override already removed.
  Future<AssetId> assetIdForElement(old_model.Element element) async => throw UnimplementedError('assetIdForElement not implemented');
}

// Helper function to get ClassElement2 from source string
Future<ClassElement2> getClassElementFromSource(String source, String className) async {
  final libraryResult = await resolveSources([source], (resolver) async { // resolveSources is from source_gen_test
    // findLibraryByName (from Resolver interface) returns old_model.LibraryElement?
    final lib = await resolver.findLibraryByName('');
    if (lib == null) {
      throw StateError('Library not found by findLibraryByName. Ensure the source is a valid library.');
    }
    // We need to ensure this old_model.LibraryElement can provide what we need
    // or this helper's goal to return ClassElement2 needs rethinking.
    // For now, this cast will likely fail if resolveSources's resolver is truly using the old model.
    // However, source_gen_test's resolveSources callback's Resolver might be different.
    // Let's assume for a moment that the resolver provided by resolveSources IS using the new model internally
    // and the issue is primarily with MockResolver's direct implementation of the build.Resolver interface.
    // The type of lib here is actually determined by the 'resolver' instance.
    // If 'resolver' is MockResolver, it returns old_model.LibraryElement.
    // If 'resolver' is from source_gen_test, it might be a new model one.
    // This is tricky. For now, let's assume resolveSources gives us a new model LibraryElement.
    return lib as LibraryElement2; // This cast is speculative.
  });
  final libraryElement = libraryResult.single.element; // This should be LibraryElement2 if the above cast worked.
  
  // Using getInterface as getClass is not available on LibraryElement2
  final interfaceElement = libraryElement.getInterface(className);
  if (interfaceElement == null || interfaceElement is! ClassElement2) {
    // Fallback or more specific search if getInterface doesn't yield ClassElement2 directly
    // This might happen if getInterface returns any InterfaceElement2, and we need to ensure it's a class.
    // A class *is* an InterfaceElement2. So if it's a class, this check should pass.
    final foundElement = libraryElement.topLevelElements.whereType<InterfaceElement2>().firstWhere(
          (e) => e.name == className && e is ClassElement2, 
          orElse: () => throw StateError('Class $className not found or is not a ClassElement2'),
        );
    return foundElement; // Removed unnecessary cast
  }
  return interfaceElement; // Removed unnecessary cast
}

Future<void> main() async {
  final mockResolver = MockResolver();

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
      
      final classElement = await getClassElementFromSource(testSource, 'TestClass1');
      final processor = GlobalResourceProcessor(classElement, mockResolver);
      final result = processor.process();

      expect(result, isNotNull, reason: "Processor result should not be null for annotated class.");
      expect(result?.className, 'TestClass1', reason: "Class name should be 'TestClass1'.");
      
      expect(result?.fields.length, 2, reason: "Should have 2 public, non-static fields.");
      expect(result?.fields.any((f) => f['name'] == 'name' && f['type'] == 'String'), isTrue, reason: "Field 'name' of type 'String' should exist.");
      expect(result?.fields.any((f) => f['name'] == 'age' && f['type'] == 'int'), isTrue, reason: "Field 'age' of type 'int' should exist.");
      
      expect(result?.constructors.length, 2, reason: "Should have 2 public, non-factory constructors.");
      // Default constructor
      final defaultConstructor = result?.constructors.firstWhere((c) => c['name'] == '', orElse: () => <String, dynamic>{});
      expect(defaultConstructor, isNotEmpty, reason: "Default constructor should exist.");
      expect(defaultConstructor?['parameters'].length, 2, reason: "Default constructor should have 2 parameters.");
      expect(defaultConstructor?['parameters'].any((p) => p['name'] == 'name' && p['type'] == 'String'), isTrue, reason: "Default constructor parameter 'name' of type 'String' should exist.");
      expect(defaultConstructor?['parameters'].any((p) => p['name'] == 'age' && p['type'] == 'int'), isTrue, reason: "Default constructor parameter 'age' of type 'int' should exist.");

      // Named constructor
      final namedConstructor = result?.constructors.firstWhere((c) => c['name'] == 'named', orElse: () => <String, dynamic>{});
      expect(namedConstructor, isNotEmpty, reason: "Named constructor 'named' should exist.");
      expect(namedConstructor?['parameters'].length, 1, reason: "Named constructor 'named' should have 1 parameter.");
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'value' && p['type'] == 'String'), isTrue, reason: "Named constructor 'named' parameter 'value' of type 'String' should exist.");
    });

    // Test 2: Class without @RdfGlobalResource annotation
    test('returns null for class without @RdfGlobalResource annotation', () async {
      final testSource = '''
        class TestClass2 {
          String data;
          TestClass2(this.data);
        }
      ''';
      final classElement = await getClassElementFromSource(testSource, 'TestClass2');
      final processor = GlobalResourceProcessor(classElement, mockResolver);
      final result = processor.process();

      expect(result, isNull, reason: "Processor result should be null for class without annotation.");
    });

    // Test 3: Class with annotation but no explicit fields/constructors
    test('processes annotated class with empty body', () async {
      final testSource = '''
        import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

        @RdfGlobalResource(null, IriStrategy('test3'))
        class TestClass3 {}
      ''';
      final classElement = await getClassElementFromSource(testSource, 'TestClass3');
      final processor = GlobalResourceProcessor(classElement, mockResolver);
      final result = processor.process();

      expect(result, isNotNull, reason: "Processor result should not be null for annotated empty class.");
      expect(result?.className, 'TestClass3', reason: "Class name should be 'TestClass3'.");
      expect(result?.fields, isEmpty, reason: "Fields list should be empty for class with no fields.");
      expect(result?.constructors.length, 1, reason: "Should have one default constructor."); // Default constructor
      expect(result?.constructors.first['name'], '', reason: "Default constructor name should be empty.");
      expect(result?.constructors.first['parameters'], isEmpty, reason: "Default constructor should have no parameters.");
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
          TestClass4.optional(this.id, [this.data]); // Optional parameters are still part of the signature
        }
      ''';
      final classElement = await getClassElementFromSource(testSource, 'TestClass4');
      final processor = GlobalResourceProcessor(classElement, mockResolver);
      final result = processor.process();

      expect(result, isNotNull, reason: "Processor result should not be null for class with multiple constructors.");
      expect(result?.className, 'TestClass4', reason: "Class name should be 'TestClass4'.");
      expect(result?.fields.length, 2, reason: "Should have 2 public, non-static fields.");
      expect(result?.fields.any((f) => f['name'] == 'id' && f['type'] == 'String'), isTrue, reason: "Field 'id' of type 'String' should exist.");
      expect(result?.fields.any((f) => f['name'] == 'data' && f['type'] == 'String?'), isTrue, reason: "Field 'data' of type 'String?' should exist."); // Nullable type
      
      expect(result?.constructors.length, 3, reason: "Should have 3 public, non-factory constructors.");

      final defaultConstructor = result?.constructors.firstWhere((c) => c['name'] == '', orElse: () => <String, dynamic>{});
      expect(defaultConstructor, isNotEmpty, reason: "Default constructor should exist.");
      expect(defaultConstructor?['parameters'].length, 1, reason: "Default constructor should have 1 parameter.");
      expect(defaultConstructor?['parameters'].first['name'], 'id', reason: "Default constructor's first parameter name should be 'id'.");
      expect(defaultConstructor?['parameters'].first['type'], 'String', reason: "Default constructor's first parameter type should be 'String'.");

      final namedConstructor = result?.constructors.firstWhere((c) => c['name'] == 'named', orElse: () => <String, dynamic>{});
      expect(namedConstructor, isNotEmpty, reason: "Named constructor 'named' should exist.");
      expect(namedConstructor?['parameters'].length, 2, reason: "Named constructor 'named' should have 2 parameters.");
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'id' && p['type'] == 'String'), isTrue, reason: "Named constructor 'named' parameter 'id' of type 'String' should exist.");
      expect(namedConstructor?['parameters'].any((p) => p['name'] == 'data' && p['type'] == 'String?'), isTrue, reason: "Named constructor 'named' parameter 'data' of type 'String?' should exist.");
      
      final optionalConstructor = result?.constructors.firstWhere((c) => c['name'] == 'optional', orElse: () => <String, dynamic>{});
      expect(optionalConstructor, isNotEmpty, reason: "Named constructor 'optional' should exist.");
      expect(optionalConstructor?['parameters'].length, 2, reason: "Named constructor 'optional' should have 2 parameters.");
      expect(optionalConstructor?['parameters'].any((p) => p['name'] == 'id' && p['type'] == 'String'), isTrue, reason: "Named constructor 'optional' parameter 'id' of type 'String' should exist.");
      expect(optionalConstructor?['parameters'].any((p) => p['name'] == 'data' && p['type'] == 'String?'), isTrue, reason: "Named constructor 'optional' parameter 'data' of type 'String?' should exist.");
    });
  });
}
// Removed old helper functions: initializeLibraryReaderForDirectory, getClassElement, resolveSource
// New helper getClassElementFromSource is at the top of the file.
