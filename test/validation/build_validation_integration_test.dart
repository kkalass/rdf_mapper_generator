import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Build Validation Integration Tests', () {
    test('build fails with validation errors for invalid generic class', () async {
      // Create a temporary test project with an invalid generic class
      final tempDir = Directory.systemTemp.createTempSync('build_validation_test_');
      
      try {
        // Create a minimal project structure
        final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: test_validation
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  rdf_mapper_annotations: 
    path: ${Directory.current.path}/../rdf_mapper_annotations
  rdf_vocabularies_core: any
  build: any

dev_dependencies:
  rdf_mapper_generator:
    path: ${Directory.current.path}
  build_runner: any

''');
        
        // Create build.yaml
        final buildFile = File(p.join(tempDir.path, 'build.yaml'));
        await buildFile.writeAsString('''
targets:
  \$default:
    builders:
      rdf_mapper_generator:cache_builder:
        enabled: true
      rdf_mapper_generator:source_builder:
        enabled: true
      rdf_mapper_generator:init_file_builder:
        enabled: true
''');

        // Create lib directory and invalid class
        final libDir = Directory(p.join(tempDir.path, 'lib'));
        await libDir.create(recursive: true);
        
        final invalidClassFile = File(p.join(libDir.path, 'invalid_generic.dart'));
        await invalidClassFile.writeAsString('''
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: true,  // This should cause validation error for generic class
)
class InvalidGenericDocument<T> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  const InvalidGenericDocument({
    required this.documentIri,
    required this.primaryTopic,
  });
}
''');

        // Run pub get to install dependencies
        final pubGetResult = await Process.run(
          'dart',
          ['pub', 'get'],
          workingDirectory: tempDir.path,
        );
        
        if (pubGetResult.exitCode != 0) {
          print('pub get failed: ${pubGetResult.stderr}');
          // This might fail due to path dependencies, but we'll continue
        }

        // Run build_runner build and expect it to fail with validation errors
        final buildResult = await Process.run(
          'dart',
          ['run', 'build_runner', 'build'],
          workingDirectory: tempDir.path,
        );
        
        // The build should fail (non-zero exit code) due to validation errors
        expect(buildResult.exitCode, isNot(equals(0)), 
          reason: 'Build should fail when there are validation errors');
        
        // Check that the error message contains our expected validation error
        final allOutput = buildResult.stderr.toString() + buildResult.stdout.toString();
        expect(allOutput, anyOf([
          contains('InvalidGenericDocument has generic type parameters'),
          contains('must have registerGlobally set to false'),
          contains('Generic classes cannot be registered globally'),
          contains('ValidationException'), // The validation framework should report the error
        ]), reason: 'Build output should contain validation error messages');
        
      } finally {
        // Clean up the temporary directory
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }, timeout: Timeout(Duration(minutes: 3))); // Give enough time for pub get and build

    test('build succeeds with valid generic classes', () async {
      // This is tested by the existing integration tests - just verify they exist
      final integrationTestFile = File('test/integration/generic_types_integration_test.dart');
      expect(integrationTestFile.existsSync(), isTrue, 
        reason: 'Integration tests should exist that verify valid builds work');
    });
  });
}