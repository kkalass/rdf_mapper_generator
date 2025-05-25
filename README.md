# RDF Mapper Generator for Dart

[![pub package](https://img.shields.io/pub/v/rdf_mapper_generator.svg)](https://pub.dev/packages/rdf_mapper_generator)
[![build](https://github.com/kkalass/rdf_mapper_generator/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_mapper_generator/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_mapper_generator/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_mapper_generator)
[![license](https://img.shields.io/github/license/kkalass/rdf_mapper_generator.svg)](https://github.com/kkalass/rdf_mapper_generator/blob/main/LICENSE)

A code generation tool for creating type-safe, boilerplate-free RDF mappers in Dart. Automatically converts between Dart objects and RDF (Resource Description Framework) data by processing annotations from rdf_mapper_annotations. Supports global and local resources, IRI templates, custom type mappings, collections, and complex object graphs while maintaining high performance and type safety.

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_mapper_generator/)

`rdf_mapper_generator` provides the builder that takes classes annotated with the annotations from `rdf_mapper_annotations` and generates Mappers for use with `rdf_mapper` project.

## Part of a Family of Projects

This library is part of a comprehensive ecosystem for working with RDF in Dart:

* [rdf_core](https://github.com/kkalass/rdf_core) - Core graph classes and serialization (Turtle, JSON-LD, N-Triples)
* [rdf_mapper](https://github.com/kkalass/rdf_mapper) - Base mapping system between Dart objects and RDF
* [rdf_mapper_generator](https://github.com/kkalass/rdf_mapper_generator) - Code generator for this annotation library
* [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies) - Constants for common RDF vocabularies (Schema.org, FOAF, etc.)
* [rdf_xml](https://github.com/kkalass/rdf_xml) - RDF/XML format support
* [rdf_vocabulary_to_dart](https://github.com/kkalass/rdf_vocabulary_to_dart) - Generate constants for custom vocabularies

## Recent Changes

### Model Class Refactoring

We've refactored the model classes to store complete annotation instances instead of individual fields. This change provides several benefits:

- **Better encapsulation**: The complete annotation data is preserved
- **Future-proof**: New annotation properties are automatically available
- **Consistency**: Uniform access to all annotation data

#### Key Changes:

1. **GlobalResourceInfo** now stores the complete `RdfGlobalResource` annotation
2. **PropertyInfo** now stores the complete `RdfProperty` annotation
3. Added computed getters for backward compatibility
4. Updated processors to create and handle complete annotation instances

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper_generator/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
