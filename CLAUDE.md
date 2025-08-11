# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Code Generation
```bash
# Generate RDF mappers from annotations (primary command)
dart run build_runner build

# Watch mode for continuous code generation during development
dart run build_runner watch

# Clean generated files
dart run build_runner clean
```

### Testing
```bash
# Run all tests
dart test

# Run tests with coverage
dart tool/run_tests.dart

# Run specific test
dart test test/specific_test.dart
```

### Code Quality
```bash
# Run static analysis
dart analyze

# Format code
dart format .
```

## Architecture Overview

This is a Dart code generator that creates type-safe RDF mappers from annotated classes. The generator follows a three-phase build pipeline:

### Three-Phase Build System

1. **Cache Builder** (`lib/cache_builder.dart`)
   - Analyzes `.dart` files for RDF annotations
   - Generates `.rdf_mapper.cache.json` files containing template data
   - Uses analyzer wrapper for cross-version compatibility with Dart analyzer

2. **Source Builder** (`lib/source_builder.dart`) 
   - Processes `.rdf_mapper.cache.json` files
   - Generates `.rdf_mapper.g.dart` files with actual mapper code
   - Uses Mustache templates for code generation

3. **Init File Builder** (`lib/init_file_builder.dart`)
   - Consolidates all mappers into initialization files
   - Generates `init_rdf_mapper.g.dart` and `init_test_rdf_mapper.g.dart`
   - Provides single entry point for mapper registration

### Core Components

**Processors** (`lib/src/processors/`)
- `resource_processor.dart` - Handles `@RdfGlobalResource` and `@RdfLocalResource` annotations
- `property_processor.dart` - Processes `@RdfProperty` annotations on class fields
- `enum_processor.dart` - Manages enum mappings with `@RdfIri` and `@RdfLiteral`
- `literal_processor.dart` - Handles custom literal types with `@RdfLiteral`
- `iri_processor.dart` - Processes IRI-based mappings

**Mappers** (`lib/src/mappers/`)
- `mapper_model_builder.dart` - Builds internal representation of mappers
- `resolved_mapper_model.dart` - Contains resolved mapper definitions
- Template data structures for code generation

**Templates** (`lib/src/templates/`)
- Mustache templates for generating different mapper types
- `template_renderer.dart` - Renders templates with data
- Code generation utilities

**Analyzer Wrapper** (`lib/src/analyzer_wrapper/`)
- Abstracts different analyzer versions (v6, v7.4)
- Provides unified interface for AST analysis
- Handles version compatibility issues

### Key Files for Understanding

- `lib/builder_helper.dart` - Main orchestration logic
- `lib/src/templates/template_data_builder.dart` - Converts analyzed classes to template data
- `build.yaml` - Build system configuration with three builders
- Test fixtures in `test/fixtures/` contain comprehensive examples of all annotation patterns

The generator supports complex RDF mapping scenarios including IRI templates, custom collections, enum mappings, lossless round-trip mapping, multi-language literals, and generic type parameters.

## Code Generation System

### The Code Class (`lib/src/templates/code.dart`)

The `Code` class is the foundation of the code generation system. It represents code snippets that will be rendered into the final generated Dart files. Understanding how `Code` works is essential when working on this codebase.

#### Key Concepts

**Code Objects vs Strings**: Instead of working with raw strings, the system uses `Code` objects that can:
- Track import dependencies automatically
- Combine multiple code fragments
- Handle type references and generic parameters
- Resolve to properly formatted code during template rendering

**Automatic String Resolution**: Code objects are automatically converted to strings during template rendering when `toMap()` is called on template data objects. You don't need to manually convert them.

#### Code Factory Methods

**Basic Construction**:
```dart
// Type references (automatically handles imports)
Code.type('MyClass', importUri: 'package:example/my_class.dart')
Code.type('List<String>')  // Built-in types need no import
Code.coreType('String')    // Dart core types

// Literal code snippets (no imports)
Code.literal('const')
Code.value('42')  // Alias for literal, semantic clarity for values

```

**Specialized List Builders**:
```dart
// Parameter lists: (param1, param2, param3)
Code.paramsList([
  Code.literal('param1'),
  Code.literal('param2'),
  Code.literal('param3')
])

// Generic parameter lists: <T, U, V>
Code.genericParamsList([
  Code.literal('T'),
  Code.literal('U'), 
  Code.literal('V')
])

// General combining with custom separators
Code.combine([
  Code.type('List'),
  Code.literal('<'),
  Code.type('MyType'),
  Code.literal('>')
])

// Custom separator (default is empty string)
Code.combine(codes, separator: ', ')
```

#### Working with Code Objects

**In Processors**: Create and manipulate Code objects to represent class names, types, and code snippets:
```dart
final className = Code.type(classElement.name);
final mapperName = Code.literal('${classElement.name}Mapper');
```

**In Template Data**: Include Code objects in template data structures:
```dart
class MyTemplateData {
  final Code className;
  final Code interfaceType;
  
  Map<String, dynamic> toMap() => {
    'className': className.toMap(),  // Auto-converts to string + imports
    'interfaceType': interfaceType.toMap(),
  };
}
```

**In Templates**: Use the resolved strings directly in mustache templates:
```mustache
class {{className}}Mapper implements {{interfaceType}} {
  // Generated code here
}
```

#### Advanced Code Manipulation

**Import and Alias Management**: Code objects automatically track their import dependencies and handle alias generation to avoid naming conflicts:
```dart
// This automatically generates proper import aliases if needed
final myClass = Code.type('MyClass', importUri: 'package:example/my_class.dart');
final otherClass = Code.type('MyClass', importUri: 'package:other/my_class.dart');
// Result: example.MyClass and other.MyClass with appropriate imports
```

**Accessing Code Properties**:
```dart
final code = Code.type('MyClass', importUri: 'package:example/my_class.dart');

// Get resolved code with aliases: "example.MyClass"
final resolvedCode = code.code;

// Get just the class name without aliases: "MyClass" 
final className = code.codeWithoutAlias;

// Get import dependencies: {"package:example/my_class.dart"}
final imports = code.imports;
```

**Adding Type Parameters** (using built-in methods):
```dart
// Clean implementation using Code.genericParamsList
Code appendTypeParameters(Code baseClass, List<String> typeParams) {
  if (typeParams.isEmpty) return baseClass;
  
  return Code.combine([
    baseClass,
    Code.genericParamsList(typeParams.map(Code.literal))
  ]);
}

// Alternative: For more complex parameter handling
Code createGenericType(Code baseType, List<Code> typeArgs) {
  return Code.combine([
    baseType,
    Code.genericParamsList(typeArgs)
  ]);
}
```

#### Best Practices

1. **Use appropriate factory methods** - `Code.type()` for types, `Code.constructor()` for constructors, etc.
2. **Leverage specialized builders** - Use `Code.paramsList()` and `Code.genericParamsList()` instead of manual bracket handling
3. **Let the template system handle string conversion** - Don't call `toString()` or `.code` manually in data processing
4. **Access raw names with `codeWithoutAlias`** - When you need the pure type name without import prefixes
5. **Enhance Code objects at the source** - Modify Code objects in processors/mappers rather than in templates
6. **Test Code object behavior** - Write unit tests to verify Code objects generate expected output

#### Common Patterns

**Creating Generic Types**:
```dart
// Modern approach using built-in methods
final genericClass = Code.combine([
  Code.type('MyClass', importUri: 'package:example/my_class.dart'),
  Code.genericParamsList([Code.literal('T'), Code.literal('U')])
]);

// For method calls with parameters
final methodCall = Code.combine([
  Code.literal('myMethod'),
  Code.paramsList([Code.literal('arg1'), Code.literal('arg2')])
]);
```

**Constructor Handling**:
```dart
// Automatically handles const constructors and import aliasing
final constructor = Code.constructor(
  'const MyClass.named(value: 42)',
  importUri: 'package:example/my_class.dart'
);
```
Note that this feature is actually nearly never used - we prefer to use the other possibilities.

**Conditional Code Generation**:
```dart
final code = hasTypeParameters 
  ? appendTypeParameters(baseClass, typeParameters)
  : baseClass;

// Or using the null-aware pattern
final finalCode = typeParameters.isNotEmpty
  ? Code.combine([baseClass, Code.genericParamsList(typeParameters.map(Code.literal))])
  : baseClass;
```

Understanding these patterns will help you work effectively with the code generation system and avoid common pitfalls like losing import information or generating malformed code.