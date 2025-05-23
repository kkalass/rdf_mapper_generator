# RDF Mapper Generator - Technical Documentation

## Overview

The `rdf_mapper_generator` is a code generation tool that works in conjunction with `rdf_mapper_annotations` to automatically generate mapping code between Dart objects and RDF (Resource Description Framework) data. This documentation provides a comprehensive guide to the generator's architecture, behavior, and implementation details.

### Purpose

The primary purpose of `rdf_mapper_generator` is to:

1. Eliminate boilerplate code for RDF serialization/deserialization
2. Ensure type safety when working with RDF data
3. Provide a declarative way to define RDF mappings using annotations
4. Support complex mapping scenarios while maintaining clean, maintainable code

### Core Concepts

- **Resource**: An entity in the RDF graph, identified by an IRI (Internationalized Resource Identifier)
- **Literal**: A simple data value (string, number, date, etc.)
- **Blank Node**: An anonymous resource without a global identifier
- **Triple**: A statement in the form of subject-predicate-object
- **Mapping**: The process of converting between Dart objects and RDF triples

### Architecture

The generator follows these main steps:

1. **Annotation Processing**: Scans Dart code for classes annotated with RDF mapping annotations
2. **Type Analysis**: Analyzes the structure and types of annotated classes
3. **Code Generation**: Generates mapper classes that implement the mapping logic
4. **Initialization**: Creates an initialization function to register all generated mappers

### Generator Input/Output

**Input:**
- Dart source files with RDF mapping annotations
- Configuration from `build.yaml`

**Output:**
- Generated mapper classes (one per annotated class)
- Initialization function to register all mappers
- Mapper registration code for the RDF mapper system

### Key Features

- Support for global and local resources
- Automatic type conversion for common Dart types
- Custom mapping strategies for complex types
- Collection support (List, Set, Map)
- IRI template resolution
- Default value handling
- Custom serialization/deserialization
- Null safety support

### Dependencies

- `rdf_core`: Core RDF data structures and operations
- `rdf_mapper`: Base mapping functionality
- `rdf_mapper_annotations`: Annotation definitions
- `build_runner`: Build system integration
- `source_gen`: Code generation utilities

### Build Configuration

The generator is configured through `build.yaml`. Here's a minimal example:

```yaml
targets:
  $default:
    builders:
      rdf_mapper_generator:rdf_mapper_generator:
        generate_for:
          - lib/**.dart
        options:
          # Generator options go here
```

### Error Handling

The generator provides detailed error messages for:
- Missing required annotations
- Type mismatches
- Invalid IRI templates
- Unsupported types
- Circular dependencies
- Invalid default values

### Performance Considerations

- Mapper classes are generated at build time
- Runtime performance is optimized for common cases
- Complex mappings may have additional overhead
- Large collections are handled efficiently

### Testing

Generated mappers should be tested for:
- Round-trip serialization/deserialization
- Edge cases (null values, empty collections, etc.)
- Custom type handling
- IRI generation and resolution
- Default value handling

### Limitations

- Private fields are not supported
- Some advanced RDF features may require custom mappers
- Complex inheritance scenarios may need special handling

### Next Steps

- [Annotations Reference](./02_annotations_reference.md)
- [Code Generation Details](./03_code_generation.md)
- [Custom Mappers](./04_custom_mappers.md)
- [Advanced Topics](./05_advanced_topics.md)
