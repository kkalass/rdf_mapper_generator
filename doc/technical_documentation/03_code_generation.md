# Code Generation Details

This document describes how the `rdf_mapper_generator` processes annotations and generates the corresponding mapping code.

## Table of Contents

1. [Generation Process](#generation-process)
2. [Generated Mapper Classes](#generated-mapper-classes)
   - [Global Resource Mapper](#global-resource-mapper)
   - [Local Resource Mapper](#local-resource-mapper)
   - [IRI Mapper](#iri-mapper)
   - [Literal Mapper](#literal-mapper)
3. [Initialization Function](#initialization-function)
4. [Type Handling](#type-handling)
5. [IRI Resolution](#iri-resolution)
6. [Collection Handling](#collection-handling)
7. [Error Handling](#error-handling)
8. [Performance Optimizations](#performance-optimizations)

## Generation Process

The code generation process consists of the following steps:

1. **Source Analysis**
   - Scan all Dart files in the target directories
   - Identify classes with RDF mapping annotations
   - Build a model of the class hierarchy and relationships

2. **Type Resolution**
   - Resolve all type references
   - Validate type compatibility
   - Handle generic types and type parameters

3. **Mapper Generation**
   - Generate a mapper class for each annotated class
   - Implement serialization/deserialization logic
   - Handle special cases (null safety, default values, etc.)

4. **Initialization**
   - Generate the initialization function
   - Register all mappers with the RDF mapper system

## Generated Mapper Classes

### Global Resource Mapper

Generated for classes annotated with `@RdfGlobalResource`.

**Key Features:**
- Implements `GlobalResourceMapper<T>`
- Handles IRI generation and parsing
- Manages resource identity
- Supports inheritance and mixins

**Example:**
```dart
class BookMapper implements GlobalResourceMapper<Book> {
  @override
  final IriTerm typeIri = SchemaBook.classIri;
  
  // IRI generation/parsing
  String _createIri(Book book) => 'http://example.org/books/${book.id}';
  String _parseId(IriTerm iri) => /* ... */;
  
  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return Book(
      id: _parseId(subject),
      title: reader.require<String>(SchemaBook.name),
      // ... other properties
    );
  }
  
  @override
  (IriTerm, List<Triple>) toRdfResource(
    Book book, 
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(_createIri(book)))
        .addValue(SchemaBook.name, book.title)
        // ... other properties
        .build();
  }
}
```

### Local Resource Mapper

Generated for classes annotated with `@RdfLocalResource`.

**Key Features:**
- Implements `LocalResourceMapper<T>`
- Uses blank nodes for resource identity
- Lighter weight than global resources

**Example:**
```dart
class ChapterMapper implements LocalResourceMapper<Chapter> {
  @override
  final IriTerm typeIri = SchemaChapter.classIri;
  
  @override
  Chapter fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Chapter(
      title: reader.require<String>(SchemaChapter.name),
      number: reader.require<int>(SchemaChapter.position),
    );
  }
  
  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
    Chapter chapter,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(SchemaChapter.name, chapter.title)
        .addValue(SchemaChapter.position, chapter.number)
        .build();
  }
}
```

### IRI Mapper

Generated for classes annotated with `@RdfIri`.

**Key Features:**
- Implements `IriTermMapper<T>`
- Handles custom IRI formatting and parsing
- Supports template-based IRI generation

**Example:**
```dart
class IsbnMapper implements IriTermMapper<ISBN> {
  static const String _prefix = 'urn:isbn:';
  
  @override
  IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
    return IriTerm('$_prefix${isbn.value}');
  }
  
  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    if (!term.iri.startsWith(_prefix)) {
      throw ArgumentError('Invalid ISBN IRI: ${term.iri}');
    }
    return ISBN(term.iri.substring(_prefix.length));
  }
}
```

### Literal Mapper

Generated for classes annotated with `@RdfLiteral`.

**Key Features:**
- Implements `LiteralTermMapper<T>`
- Handles custom literal serialization
- Supports datatypes and language tags

**Example:**
```dart
class RatingMapper implements LiteralTermMapper<Rating> {
  @override
  LiteralTerm toRdfTerm(Rating rating, SerializationContext context) {
    return LiteralTerm(
      rating.stars.toString(),
      datatype: XSD.integer,
    );
  }
  
  @override
  Rating fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    final stars = int.parse(term.value);
    return Rating(stars);
  }
}
```

## Initialization Function

The generator creates an initialization function that registers all generated mappers:

```dart
RdfMapper initRdfMapper({
  String? baseUri,
  Map<String, dynamic> context = const {},
}) {
  final mapper = RdfMapper(
    baseUri: baseUri,
    context: context,
  );
  
  // Register all mappers
  mapper.registerGlobalResource<Book>(BookMapper());
  mapper.registerLocalResource<Chapter>(ChapterMapper());
  mapper.registerIriTerm<ISBN>(IsbnMapper());
  mapper.registerLiteralTerm<Rating>(RatingMapper());
  
  return mapper;
}
```

## Type Handling

The generator handles various Dart types:

### Primitive Types
- `String` → `xsd:string`
- `int` → `xsd:integer`
- `double` → `xsd:double`
- `bool` → `xsd:boolean`
- `DateTime` → `xsd:dateTime`
- `Uri` → `xsd:anyURI`

### Collection Types
- `List<T>` → Multiple triples with the same predicate
- `Set<T>` → Multiple triples with the same predicate (duplicates removed)
- `Map<K, V>` → Key-value pairs (requires `@RdfMapEntry`)

### Null Safety
- Non-nullable types are required during deserialization
- Nullable types (`T?`) are optional
- Default values can be specified using `defaultValue`

## IRI Resolution

IRIs are resolved using the following rules:

1. **Template Resolution**
   - Replace placeholders with property values
   - Handle URL encoding
   - Support for context variables

2. **Base IRI**
   - Can be provided globally or per-resource
   - Falls back to the document base IRI

3. **Relative IRIs**
   - Resolved against the base IRI
   - Support for `../` and `./` relative paths

## Collection Handling

### Lists and Sets
- Each item generates a separate triple with the same predicate
- Order is preserved for lists, not for sets
- Empty collections are omitted by default

### Maps
- Each key-value pair is mapped to a separate resource
- The key and value are mapped according to their types
- Supports custom key/value mappers

## Error Handling

The generator includes comprehensive error handling:

### Compile-Time Errors
- Missing required annotations
- Type mismatches
- Invalid IRI templates
- Unsupported types
- Circular dependencies

### Runtime Errors
- Missing required values
- Invalid data formats
- IRI resolution failures
- Custom validation errors

## Performance Optimizations

1. **Caching**
   - Mapper instances are cached
   - IRI resolution results are cached
   - Type lookups are optimized

2. **Lazy Initialization**
   - Mappers are initialized on first use
   - Heavy operations are deferred

3. **Minimal Reflection**
   - Uses code generation instead of reflection
   - Avoids runtime type checks

4. **Efficient Collections**
   - Uses lazy evaluation where possible
   - Minimizes copying of data
   - Optimized for common cases
