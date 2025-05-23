# RDF Mapper Generator - Detailed Implementation Plan

This document provides a step-by-step guide for implementing the `rdf_mapper_generator` package. Each task is designed to be small, focused, and testable.

Provide the LLM with the files in doc/technical_documentation and with a reference to rdf_mapper_annotations project so it can read the actual annotation source code files and examples as context.

## Phase 1: Project Setup

### Task 1.1: Create Basic Package Structure
```
1. Create a new directory called 'rdf_mapper_generator'
2. Run 'dart create --template=package rdf_mapper_generator'
3. Update pubspec.yaml with these dependencies:
   dependencies:
     analyzer: ^5.0.0
     build: ^2.0.0
     source_gen: ^1.0.0
     rdf_mapper_annotations: ^1.0.0
     rdf_core: ^1.0.0
   dev_dependencies:
     build_runner: ^2.0.0
     test: ^1.0.0
     build_test: ^2.0.0
4. Create basic README.md with package description
5. Add MIT LICENSE file
6. Create .gitignore for Dart projects
```
**Note**: I preferred to implement this step myself...

### Task 1.2: Configure Build System
```
1. Create build.yaml with this configuration:
   targets:
     $default:
       builders:
         rdf_mapper_generator|rdf_mapper_generator:
           generate_for:
             - lib/**.dart
   builders:
     rdf_mapper_generator:
       import: 'package:rdf_mapper_generator/builder.dart'
       builder_factories: ['rdfMapperBuilder']
       build_extensions: { '.dart': ['.g.dart'] }
       build_to: source
       auto_apply: dependents
       applies_builders: ['source_gen|combining_builder']
2. Create lib/rdf_mapper_generator.dart with basic exports
```

## Phase 2: Core Analysis Components

### Task 2.1: Create Basic Builder
```
1. Create lib/builder.dart with:
   - Basic Builder class
   - Empty build method
   - Basic error handling
2. Add tests for builder initialization
3. Verify build.yaml is correctly set up
```

### Task 2.2: Process RdfGlobalResource Annotation
```
1. Create lib/src/processors/global_resource_processor.dart
2. Implement logic to detect @RdfGlobalResource annotation
3. Extract basic class information (name, constructors, fields)
4. Add tests with simple class examples
```

### Task 2.3: Process RdfProperty Annotation
```
1. Create lib/src/processors/property_processor.dart
2. Implement logic to process @RdfProperty on fields
3. Extract property name, type, and annotation parameters
4. Handle basic type resolution
5. Add tests for different property types
```

### Task 2.4: Process IriStrategy
```
1. Create lib/src/processors/iri_strategy_processor.dart
2. Implement IRI template parsing
3. Handle variable extraction from templates
4. Validate IRI patterns
5. Add tests for various IRI templates
```

## Phase 3: Code Generation

### Task 3.1: Generate Basic Mapper Class
```
1. Create lib/src/generators/class_mapper_generator.dart
2. Generate empty mapper class
3. Add basic class structure with imports
4. Add tests for class generation
```

### Task 3.2: Generate Property Mappers
```
1. Extend class_mapper_generator.dart
2. Generate toRdf method
3. Generate fromRdf constructor
4. Handle basic property types
5. Add tests for property mapping
```

### Task 3.3: Implement IRI Generation
```
1. Create lib/src/generators/iri_generator.dart
2. Generate IRI resolution code
3. Handle template variables
4. Add tests for IRI generation
```

### Task 3.4: Handle Collections
```
1. Extend property processor to detect collections
2. Generate collection handling code
3. Support List, Set, and Map types
4. Add tests for collection handling
```

## Phase 4: Advanced Features

### Task 4.1: Support Inheritance
```
1. Update class analyzer to detect inheritance
2. Generate proper type checking
3. Handle parent class properties
4. Add tests for inheritance
```

### Task 4.2: Custom Type Mappers
```
1. Add support for @RdfTypeMapper
2. Generate registration code for custom mappers
3. Handle custom type resolution
4. Add tests for custom types
```

### Task 4.3: Validation
```
1. Add input validation
2. Generate validation code
3. Add error messages
4. Test validation scenarios
```

## Phase 5: Testing & Documentation

### Task 5.1: Add Example Project
```
1. Create example/ directory
2. Add simple example model
3. Add build script
4. Verify code generation works
```

### Task 5.2: Write Documentation
```
1. Document public APIs
2. Add usage examples
3. Write README
4. Add API reference
```

### Task 5.3: Add Integration Tests
```
1. Create integration tests
2. Test real-world scenarios
3. Verify edge cases
4. Test with complex models
```

## Phase 3: Element Analysis

### Task 3.1: Create Type Resolver
```
Create lib/src/analyzers/type_resolver.dart:
- Resolve Dart types to RDF types
- Handle generics
- Support built-in types
- Add tests
```

### Task 3.2: Create Property Analyzer
```
Create lib/src/analyzers/property_analyzer.dart:
- Process field annotations
- Extract property metadata
- Validate configurations
- Add tests
```

### Task 3.3: Create Class Analyzer
```
Create lib/src/analyzers/class_analyzer.dart:
- Process class annotations
- Collect class metadata
- Validate class structure
- Add tests
```

## Phase 4: Code Generation

### Task 4.1: Create Code Utilities
```
Create lib/src/generators/utils/code_utils.dart:
- Common code generation utilities
- String manipulation
- Type conversion
- Helper methods
```

### Task 4.2: Implement Literal Generator
```
Create lib/src/generators/literal_generator.dart:
- Generate code for literals
- Handle default values
- Support custom serialization
- Add tests
```

### Task 4.3: Implement IRI Generator
```
Create lib/src/generators/iri_generator.dart:
- Generate IRI resolution code
- Handle templates
- Support custom mappers
- Add tests
```

### Task 4.4: Implement Resource Generator
```
Create lib/src/generators/resource_generator.dart:
- Generate resource mappers
- Handle inheritance
- Support collections
- Add tests
```

## Phase 5: Builder Implementation

### Task 5.1: Create Base Builder
```
Create lib/src/builders/base_builder.dart:
- Basic builder structure
- Common utilities
- Error handling
- Logging
```

### Task 5.2: Implement Resource Builder
```
Create lib/src/builders/resource_builder.dart:
- Process resource annotations
- Generate mapper classes
- Handle part files
- Add tests
```

### Task 5.3: Implement Library Builder
```
Create lib/src/builders/library_builder.dart:
- Process library directives
- Generate exports
- Handle multiple classes
- Add tests
```

## Phase 6: Testing

### Task 6.1: Test Utilities
```
Create test/test_utils.dart:
- Test models
- Common test utilities
- Assertion helpers
- Golden file support
```

### Task 6.2: Unit Tests
```
Create unit tests for:
- Models
- Analyzers
- Generators
- Builders
```

### Task 6.3: Integration Tests
```
Create integration tests for:
- Full serialization/deserialization
- Edge cases
- Error conditions
- Performance
```

## Phase 7: Documentation

### Task 7.1: API Documentation
```
Add documentation for:
- Public APIs
- Examples
- Common patterns
- Error handling
```

### Task 7.2: User Guide
```
Create user guide covering:
- Getting started
- Basic usage
- Advanced features
- Troubleshooting
```

## Phase 8: Publishing

### Task 8.1: Prepare for Release
```
- Update version numbers
- Generate CHANGELOG.md
- Update README.md
- Verify licenses
```

### Task 8.2: Publish to pub.dev
```
- Run all tests
- Generate documentation
- Publish package
- Create release notes
```

## Implementation Order

1. Complete tasks in numerical order
2. Each task should be fully tested
3. Document as you go
4. Review after each phase

## Task Dependencies

- 1.x tasks must be completed first
- 2.x tasks depend on 1.x
- 3.x tasks depend on 2.x
- And so on...

## Quality Checks

- All code must be tested
- No analysis warnings
- Documentation complete
- Examples work
- Performance acceptable

## Maintenance Tasks

- Update dependencies
- Fix bugs
- Add features
- Improve documentation
- Optimize performance
