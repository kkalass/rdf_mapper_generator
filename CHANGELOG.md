# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.1] - 2025-08-11

### Added

- **Generic Type Parameter Support**: Full support for generating type-safe mappers from generic classes
  - Classes with type parameters (e.g., `Document<T>`) now generate corresponding generic mappers (e.g., `DocumentMapper<T>`)  
  - Generated mappers properly implement generic interfaces like `GlobalResourceMapper<Document<T>>`
  - Support for single and multiple type parameters (e.g., `MultiGenericDocument<T, U, V>`)
  - Preserved original type parameter syntax in generated code (e.g., `final T primaryTopic`)
- **Generic Type Validation**: Comprehensive validation for generic class usage
  - Generic classes must have `registerGlobally: false` since they cannot be registered without concrete types
  - Clear error messages when validation fails: "Generic classes cannot be registered globally because they require concrete type parameters"
  - Validation applies to both `@RdfGlobalResource` and `@RdfLocalResource` annotations
- **Enhanced Analyzer Wrapper**: Extended analyzer API abstraction for generic type detection
  - Added `hasTypeParameters` and `typeParameterNames` properties to `ClassElem` interface
  - Compatible with both analyzer v6 and v7.4 through version-specific implementations
  - Proper handling of type parameter extraction across different analyzer versions

### Changed

- **Code Generation Pipeline**: Enhanced template data generation to preserve generic type information
  - Modified `ResourceProcessor` to extract and validate generic type parameters
  - Updated `ResolvedMapperModel` to append type parameters using `Code.genericParamsList()` method
  - Enhanced mustache templates to generate correct generic mapper syntax
- **Test Infrastructure**: Improved testing capabilities for validation logic
  - Added `buildTemplateDataFromString()` helper method for string-based testing
  - Created comprehensive test suites covering processor validation, integration tests, and template generation
  - Consolidated duplicate test fixture files for better maintainability

### Fixed

- **Build System Compatibility**: Resolved build failures caused by invalid generic test classes
  - Removed invalid test classes with conflicting `registerGlobally: true` settings
  - Implemented string-based validation testing to avoid build-time errors
  - Ensured clean project builds with proper validation error reporting

## [0.10.0] - 2025-07-25

### Changed

- **Breaking Change**: Updated `rdf_vocabularies` dependency to use the new multipackage structure:
  - Replaced `rdf_vocabularies: ^0.3.0` with `rdf_vocabularies_core: ^0.4.1` and `rdf_vocabularies_schema: ^0.4.1`
  - Updated all import statements throughout the codebase to use the new package structure
  - `import 'package:rdf_vocabularies/rdf.dart'` → `import 'package:rdf_vocabularies_core/rdf.dart'`
  - `import 'package:rdf_vocabularies/xsd.dart'` → `import 'package:rdf_vocabularies_core/xsd.dart'`
  - `import 'package:rdf_vocabularies/schema.dart'` → `import 'package:rdf_vocabularies_schema/schema.dart'`
  - And similar updates for other vocabulary imports (`foaf`, `vcard`, etc.)

## [0.3.3] - 2025-07-24

### Added

- Automated dependency management with Dependabot configuration for weekly updates

### Changed

- **BREAKING**: Updated `build` dependency from 2.5.4 to 3.0.0 for improved build performance and compatibility, but continue to support older build versions
- Updated dependency versions:
  - `dart_style` from 3.1.0 to 3.1.1
  - `analyzer` from 7.7.0 to 7.7.1  
  - `rdf_core` from 0.9.7 to 0.9.11
  - `rdf_mapper` from 0.9.2 to 0.9.3
  - `rdf_mapper_annotations` from 0.3.1 to 0.3.2
  - Various test dependencies updated to latest versions

### Fixed

- Compatibility with `build` package 3.0.0 by adding explicit type cast in analyzer wrapper
- Code cleanup in analyzer v7.4 wrapper by removing unused exports

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
