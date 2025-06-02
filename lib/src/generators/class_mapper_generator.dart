import 'package:code_builder/code_builder.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';

/// Generates mapper classes for RDF resource mappings.
///
/// This generator creates mapper classes that implement the appropriate interfaces
/// for converting between Dart objects and RDF triples.
class ClassMapperGenerator {
  /// Generates the complete mapper class code for a global resource.
  ///
  /// Creates a class that implements `GlobalResourceMapper<T>` with the necessary
  /// methods for serialization and deserialization.
  static String generateGlobalResourceMapper(GlobalResourceInfo resourceInfo) {
    final className = resourceInfo.className;
    final mapperClassName = '${className}Mapper';

    // Build the mapper class using code_builder
    final mapperClass = Class((b) => b
      ..name = mapperClassName
      ..docs.add('/// Generated mapper for [$className] global resources.')
      ..implements.add(refer('GlobalResourceMapper<$className>'))
      ..fields.addAll(_buildFields(resourceInfo))
      ..methods.addAll(_buildMethods(resourceInfo)));

    // Generate the complete file with imports
    final library = Library((b) => b
      ..directives.addAll(_buildImports(resourceInfo))
      ..body.add(mapperClass));

    // Emit the code
    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      orderDirectives: true,
      useNullSafetySyntax: true,
    );

    final code = library.accept(emitter).toString();

    // Fix formatting issues that code_builder doesn't handle well
    return _formatGeneratedCode(code);
  }

  /// Builds the import directives for the generated file.
  static List<Directive> _buildImports(GlobalResourceInfo resourceInfo) {
    final imports = <String>[
      'package:rdf_core/rdf_core.dart',
      'package:rdf_mapper/rdf_mapper.dart',
    ];

    // Add import for the classIri reference if needed
    final classIriRef = resourceInfo.annotation.classIriSourceRef;
    if (classIriRef?.importUri != null) {
      imports.add(classIriRef!.importUri!);
    }

    return imports.map((uri) => Directive.import(uri)).toList();
  }

  /// Builds the fields for the mapper class.
  static List<Field> _buildFields(GlobalResourceInfo resourceInfo) {
    final fields = <Field>[];

    // Add typeIri field if classIri is provided
    if (resourceInfo.annotation.classIri != null) {
      // Use source reference if available, otherwise use the literal IRI value
      final classIriRef = resourceInfo.annotation.classIriSourceRef;
      final typeIriValue = classIriRef != null
          ? Code(classIriRef.reference)
          : Code('IriTerm(\'${resourceInfo.annotation.classIri!.iri}\')');
      fields.add(Field((b) => b
        ..name = 'typeIri'
        ..modifier = FieldModifier.final$
        ..type = refer('IriTerm')
        ..assignment = typeIriValue
        ..annotations.add(refer('override'))));
    }

    return fields;
  }

  /// Builds the methods for the mapper class.
  static List<Method> _buildMethods(GlobalResourceInfo resourceInfo) {
    final className = resourceInfo.className;

    return [
      _buildFromRdfResourceMethod(className),
      _buildToRdfResourceMethod(className),
    ];
  }

  /// Builds the fromRdfResource method.
  static Method _buildFromRdfResourceMethod(String className) {
    return Method((b) => b
      ..name = 'fromRdfResource'
      ..returns = refer(className)
      ..annotations.add(refer('override'))
      ..requiredParameters.addAll([
        Parameter((p) => p
          ..name = 'subject'
          ..type = refer('IriTerm')),
        Parameter((p) => p
          ..name = 'context'
          ..type = refer('DeserializationContext')),
      ])
      ..body = Code('''
    // TODO: Implement deserialization logic
    throw UnimplementedError('Deserialization not yet implemented');
  '''));
  }

  /// Builds the toRdfResource method.
  static Method _buildToRdfResourceMethod(String className) {
    return Method((b) => b
      ..name = 'toRdfResource'
      ..returns = refer('(IriTerm, List<Triple>)')
      ..annotations.add(refer('override'))
      ..requiredParameters.addAll([
        Parameter((p) => p
          ..name = 'resource'
          ..type = refer(className)),
        Parameter((p) => p
          ..name = 'context'
          ..type = refer('SerializationContext')),
      ])
      ..optionalParameters.add(
        Parameter((p) => p
          ..name = 'parentSubject'
          ..type = refer('RdfSubject?')
          ..named = true),
      )
      ..body = Code('''
    // TODO: Implement serialization logic
    throw UnimplementedError('Serialization not yet implemented');
  '''));
  }

  /// Formats the generated code to fix issues with code_builder output.
  ///
  /// Addresses common formatting problems:
  /// - Removes trailing commas in parameter lists that cause syntax errors
  /// - Adds proper line breaks between import statements and around class definitions
  /// - Fixes brace formatting and spacing
  static String _formatGeneratedCode(String code) {
    var formattedCode = code;

    // Fix trailing commas in parameter lists that would cause syntax errors
    // Pattern: ', )' -> ')'
    formattedCode = formattedCode.replaceAll(RegExp(r',\s*\)'), ')');

    // Fix import statements that are concatenated without line breaks
    // Add line breaks between imports and after imports
    formattedCode =
        formattedCode.replaceAll(RegExp(r';\s*import'), ';\nimport');

    // Ensure proper line break between imports and class comment/definition
    formattedCode = formattedCode.replaceAll(RegExp(r';\s*///'), ';\n\n///');
    formattedCode =
        formattedCode.replaceAll(RegExp(r';\s*class'), ';\n\nclass');

    // Fix method body formatting - add proper line breaks in method bodies
    formattedCode = formattedCode.replaceAll(RegExp(r'\{\s*//'), '{\n    //');
    formattedCode = formattedCode.replaceAll(RegExp(r';\s*\}'), ';\n  }');

    // Fix class brace formatting - ensure class has proper brace structure
    formattedCode =
        formattedCode.replaceAll(RegExp(r'\{\s*@override'), '{\n  @override');
    formattedCode = formattedCode.replaceAll(RegExp(r'\}\s*\}$'), '}\n}');

    // Ensure file ends with single closing brace
    formattedCode = formattedCode.trim();
    if (!formattedCode.endsWith('}')) {
      formattedCode += '\n}';
    }

    return formattedCode;
  }
}
