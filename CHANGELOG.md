# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2025-07-04

### Fixed

- Corrected example code in README.md

## [0.2.2] - 2025-07-04

### Added

- Professional homepage at doc/index.html with modern design and feature highlights
- `ignore_for_file: unused_field` directive to generated files to suppress analyzer warnings

### Changed

- Major rewrite and modernization of README.md with clearer feature descriptions
- Improved documentation accuracy and removed overstated claims
- Enhanced onboarding experience with better "Try It" section
- Restructured documentation to be more compelling and professional for new users
- Cleaned up test fixtures for better maintainability


## [0.2.1] - 2025-07-04

### Fixed

- Fixed Stack Overflow error caused by infinite recursion in BroaderImports when processing circular library exports
- Added cycle detection to prevent infinite loops in library import/export resolution
- Fixed regex pattern rendering bug where regex patterns were not properly escaped as raw strings in generated code

## [0.2.0] - 2025-07-04

### Changed

- Expanded analyzer package version support to include older versions (>6.9.0 <8.0.0)
- Added analyzer API wrapper layer to ensure compatibility across analyzer versions
- Updated dart_style dependency constraints to support broader version range

### Fixed

- Compatibility issues with analyzer package versions 6.x
- Build compatibility with projects using older analyzer versions

## [0.1.0] - 2025-07-03

### Added

- Full support for all annotations from rdf_mapper_annotations 0.2.2:
  - Resource annotations (@RdfGlobalResource, @RdfLocalResource)
  - IRI processing (@RdfIri, @RdfIriPart) with template support
  - Literal processing (@RdfLiteral, @RdfValue)
  - Property annotations (@RdfProperty) with various mapping options
  - Collection support (Lists, Sets, Maps)
  - Map entry processing (@RdfMapEntry, @RdfMapKey, @RdfMapValue)
  - Enumeration support with @RdfEnumValue
  - Language tag support via @RdfLanguageTag
- Dynamic IRI resolution with template variables and context variables
- Provider-based IRI strategies for flexible URI creation
- Type-safe mapper generation for global and local resources
- Automatic registration of generated mappers
- Custom mapper integration (named, by type, and by instance)
- Smart type inference for RDF annotations with `registerGlobally: false` option
- Validation and comprehensive error messages
- Complete serialization and deserialization between Dart objects and RDF triples
- Support for complex object graphs
- Mustache templates for code generation
- Regular expression-based IRI parsing and creation
- Auto-generated mapper documentation
- Nested resource serialization and deserialization

### Engineering

- Multi-layered architecture with model and resolved model layers
- Structured code generation system with separate processors for different annotation types
- Clean separation between parsing, analysis, and code generation
- Comprehensive test suite covering all generated mapper scenarios
- Advanced type inference system for property resolution
- Modular template system for code generation
- Performance optimizations for working with complex object graphs
- Code abstraction for better maintainability
