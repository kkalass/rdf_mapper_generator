# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2] - 2025-07-18

### Added

- Added `hasInitializer` and `isSettable` properties to field analysis for better code generation control
- Added comprehensive collection mapping test coverage including all collection types and edge cases

### Changed

- Refactored internal model class names for improved clarity:
  - `FieldInfo` → `PropertyInfo`
  - `PropertyInfo` → `RdfPropertyInfo`
  - `RdfPropertyInfo` → `RdfPropertyAnnotationInfo`
- Renamed collection type detection methods for consistency:
  - `isList` → `isCoreList`
  - `isMap` → `isCoreMap`
  - `isSet` → `isCoreSet`
  - `isCollection` → `isCoreCollection`
- Updated internal property structures to use `properties` instead of `fields` for consistency with RDF terminology

### Fixed

- Improved analyzer wrapper to properly detect field initializers and settability
- Removed warning about missing constructor parameter during build_runner that happened for initialized final fields and getters without accompanying setters
- Detection if something is a collection sometimes did not work, itemType override thus failed for custom collection types
- important constants like rdfList, rdfSeq etc. were not documented at all

## [0.3.1] - 2025-07-17

### Added

- Added additional test cases for collection property annotation mapper generating.

### Fixed

- Fixed collection item mapper type generation where item mappers were incorrectly typed for the collection type instead of the individual item type (e.g., `IriTermMapper<List<String>>` now correctly generates as `IriTermMapper<String>`)
- Fixed parameter naming inconsistency in collection mappers where custom serializer/deserializer parameters are now correctly named `itemSerializer`/`itemDeserializer` instead of `serializer`/`deserializer` when dealing with collection item mappers
- Improved documentation formatting in generated IRI mappers by properly wrapping class names in backticks

## [0.3.0] - 2025-07-17

### Changed

- Support powerfull collection mapping
- **BREAKING**: Updated `toRdfResource` return type from `(RdfSubject, List<Triple>)` to `(RdfSubject, Iterable<Triple>)` for improved performance and flexibility
- **BREAKING**: Standardized custom mapper parameter names in generated code:
  - `iriTermDeserializer`/`iriTermSerializer` → `deserializer`/`serializer`
  - `literalTermDeserializer`/`literalTermSerializer` → `deserializer`/`serializer` 
  - `globalResourceDeserializer`/`resourceSerializer` → `deserializer`/`serializer`
  - `localResourceDeserializer`/`resourceSerializer` → `deserializer`/`serializer`
- **BREAKING**: Updated `@RdfLiteral.custom` method signatures to use `LiteralContent` instead of `LiteralTerm`:
  - `toLiteralTermMethod` and `fromLiteralTermMethod` now work with `LiteralContent` objects
  - Methods are automatically wrapped with proper datatype handling in generated code
- Added `datatype` field to generated `LiteralTermMapper` and `IriTermMapper` implementations for better type safety

### Fixed

- Improved datatype handling in custom literal mappers with explicit datatype support
- Enhanced method call generation for custom literal conversion methods

## [0.2.4] - 2025-07-10

### Added

- **Lossless Mapping Support**: Added complete support for `@RdfUnmappedTriples` annotation to enable lossless round-trip RDF mapping
  - Fields annotated with `@RdfUnmappedTriples` capture all triples not explicitly mapped to other class properties
  - Generated code includes `reader.getUnmapped<T>()` calls for deserialization and `builder.addUnmapped(field)` calls for serialization
  - Supports custom types with registered `UnmappedTriplesMapper<T>` implementations
  - `RdfGraph` type has built-in support and is recommended for most use cases
- **Enhanced Validation**: Added comprehensive validation for `@RdfUnmappedTriples` usage
  - Error when multiple fields per class are annotated with `@RdfUnmappedTriples`
  - Warning when non-`RdfGraph` types are used with clear guidance about custom mapper registration
- **Improved Developer Experience**: Enhanced warning and error message formatting
  - Professional, structured warning messages with bullet points for better readability
  - Clear, actionable guidance for resolving validation issues
  - Improved build-time feedback for annotation usage problems

### Fixed

- Fixed logging configuration for proper warning display during build_runner execution
- Ensured `getUnmapped()` calls are always executed last during deserialization for correct lossless mapping behavior

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
