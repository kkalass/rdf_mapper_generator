# Annotations Reference

This document provides a comprehensive reference for all annotations provided by `rdf_mapper_annotations` and processed by `rdf_mapper_generator`.

## Table of Contents

1. [Class-Level Annotations](#class-level-annotations)
   - [@RdfGlobalResource](#rdfglobalresource)
   - [@RdfLocalResource](#rdflocalresource)
   - [@RdfIri](#rdfiri)
   - [@RdfLiteral](#rdfliteral)

2. [Property-Level Annotations](#property-level-annotations)
   - [@RdfProperty](#rdfproperty)
   - [@RdfIriPart](#rdfiripart)
   - [@RdfValue](#rdfvalue)
   - [@RdfProvides](#rdfprovides)
   - [@RdfLanguageTag](#rdflanguagetag)

3. [Collection Annotations](#collection-annotations)
   - [@RdfMapEntry](#rdfmapentry)
   - [@RdfMapKey](#rdfmapkey)
   - [@RdfMapValue](#rdfmapvalue)

4. [Mapping Configuration](#mapping-configuration)
   - [IriStrategy](#iristrategy)
   - [IriMapping](#irimapping)
   - [LiteralMapping](#literalmapping)
   - [LocalResourceMapping](#localresourcemapping)
   - [GlobalResourceMapping](#globalresourcemapping)
   - [RdfCollectionType](#rdfcollectiontype)

## Class-Level Annotations

### @RdfGlobalResource

Marks a class as a global RDF resource with a unique IRI.

**Properties:**
- `typeIri`: The RDF type IRI for this resource (required)
- `iriStrategy`: The strategy for generating IRIs (default: `IriStrategy('{type}/{id}')`)
- `registerGlobally`: Whether to register this mapper globally (default: `true`)

**Example:**
```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  iriStrategy: IriStrategy('http://example.org/books/{isbn}'),
  registerGlobally: true,
)
class Book {
  @RdfIriPart()
  final String isbn;
  // ...
}
```

### @RdfLocalResource

Marks a class as a local RDF resource (blank node).

**Properties:**
- `typeIri`: The RDF type IRI for this resource (required)

**Example:**
```dart
@RdfLocalResource(SchemaChapter.classIri)
class Chapter {
  final String title;
  // ...
}
```

### @RdfIri

Marks a class that represents an IRI with special parsing/formatting.

**Properties:**
- `template`: The IRI template string (required)

**Example:**
```dart
@RdfIri('urn:isbn:{value}')
class ISBN {
  @RdfIriPart()
  final String value;
  // ...
}
```

### @RdfLiteral

Marks a class that represents a literal value with custom parsing/formatting.

**Properties:**
- `datatype`: The RDF datatype IRI (default: inferred from Dart type)
- `language`: The language tag for language-tagged strings

**Example:**
```dart
@RdfLiteral()
class Rating {
  @RdfValue()
  final int stars;
  // ...
}
```

## Property-Level Annotations

### @RdfProperty

Maps a property to an RDF predicate.

**Properties:**
- `predicate`: The RDF predicate IRI (required)
- `iri`: IRI mapping configuration
- `literal`: Literal mapping configuration
- `localResource`: Local resource mapping configuration
- `globalResource`: Global resource mapping configuration
- `collection`: Collection type configuration
- `defaultValue`: Default value for the property
- `include`: Whether to include this property in serialization
- `required`: Whether this property is required
- `includeDefaultsInSerialization`: Whether to include default values in serialization

**Example:**
```dart
@RdfProperty(
  SchemaBook.author,
  iri: IriMapping('http://example.org/authors/{authorId}'),
  required: true,
  includeDefaultsInSerialization: true,
)
final String authorId;
```

### @RdfIriPart

Marks a property as part of an IRI template.

**Properties:**
- `name`: The name to use in the IRI template (default: property name)
- `encode`: Whether to URL-encode the value (default: true)

**Example:**
```dart
@RdfIriPart(name: 'bookId', encode: true)
final String id;
```

### @RdfValue

Marks the primary value property of a class (for use with `@RdfLiteral`).

**Example:**
```dart
@RdfLiteral()
class Email {
  @RdfValue()
  final String value;
  // ...
}
```

### @RdfProvides

Marks a property as providing a named value for IRI templates.

**Properties:**
- `name`: The name of the provided value (required)

**Example:**
```dart
@RdfProvides('baseUri')
String get baseUri => 'https://example.org';
```

### @RdfLanguageTag

Specifies the language tag for a string property.

**Properties:**
- `value`: The language tag (e.g., 'en', 'de', 'fr')

**Example:**
```dart
@RdfProperty(SchemaBook.title)
@RdfLanguageTag('en')
final String title;
```

## Collection Annotations

### @RdfMapEntry

Marks a class as a map entry for RDF mapping.

**Example:**
```dart
@RdfMapEntry()
class LocalizedString {
  @RdfMapKey()
  final String language;
  
  @RdfMapValue()
  final String value;
  // ...
}
```

### @RdfMapKey

Marks a property as the key in a map entry.

### @RdfMapValue

Marks a property as the value in a map entry.

## Mapping Configuration

### IriStrategy

Defines how to generate IRIs for a resource.

**Properties:**
- `template`: The IRI template string (required)
- `baseIriProvider`: The name of a function that provides the base IRI

**Example:**
```dart
IriStrategy(
  'http://example.org/books/{id}',
  baseIriProvider: 'getBaseUri',
)
```

### IriMapping

Configures how to map a property to/from an IRI.

**Properties:**
- `template`: The IRI template string
- `mapper`: The name of a custom mapper function
- `mapperInstance`: An instance of a custom mapper

**Example:**
```dart
IriMapping(
  'http://example.org/authors/{authorId}',
  mapper: 'customAuthorMapper',
)
```

### LiteralMapping

Configures how to map a property to/from a literal.

**Properties:**
- `datatype`: The RDF datatype IRI
- `language`: The language tag
- `mapper`: The name of a custom mapper function
- `mapperInstance`: An instance of a custom mapper

**Example:**
```dart
LiteralMapping(
  datatype: XSD.dateTime,
  mapper: 'customDateMapper',
)
```

### LocalResourceMapping

Configures how to map a property to/from a local resource.

**Properties:**
- `mapper`: The name of a custom mapper function
- `mapperInstance`: An instance of a custom mapper

### GlobalResourceMapping

Configures how to map a property to/from a global resource.

**Properties:**
- `mapper`: The name of a custom mapper function
- `mapperInstance`: An instance of a custom mapper
- `template`: The IRI template string

### RdfCollectionType

Defines how to handle collection properties.

**Values:**
- `none`: Treat as a single value
- `list`: Treat as an ordered collection (List)
- `set`: Treat as an unordered collection (Set)
- `map`: Treat as a key-value mapping (Map)

**Example:**
```dart
@RdfProperty(
  SchemaBook.keywords,
  collection: RdfCollectionType.set,
)
final Set<String> keywords;
```
