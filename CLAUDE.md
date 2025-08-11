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

The generator supports complex RDF mapping scenarios including IRI templates, custom collections, enum mappings, lossless round-trip mapping, and multi-language literals.