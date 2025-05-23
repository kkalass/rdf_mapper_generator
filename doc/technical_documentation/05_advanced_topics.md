# Advanced Topics

This document covers advanced topics and edge cases in the RDF Mapper Generator.

## Table of Contents

1. [Dynamic IRI Resolution](#dynamic-iri-resolution)
2. [Polymorphic Types](#polymorphic-types)
3. [Custom Validation](#custom-validation)
4. [Versioning and Evolution](#versioning-and-evolution)
5. [Performance Optimization](#performance-optimization)
6. [Security Considerations](#security-considerations)
7. [Testing Strategies](#testing-strategies)
8. [Debugging Generated Code](#debugging-generated-code)
9. [Extending the Generator](#extending-the-generator)
10. [Best Practices](#best-practices)

## Dynamic IRI Resolution

### Context-Dependent IRIs

IRIs can be resolved dynamically based on runtime context:

```dart
class User {
  @RdfIriPart()
  final String id;
  
  @RdfProvides('tenantId')
  final String tenantId;
  
  @RdfProperty(
    SchemaPerson.email,
    iri: IriMapping('https://{tenantId}.example.org/users/{id}'),
  )
  final String email;
  
  // ...
}
```

### IRI Providers

Register custom IRI providers for dynamic IRI generation:

```dart
void main() {
  final mapper = RdfMapper(
    context: {
      'baseUri': () => 'https://api.example.org',
      'version': () => 'v1',
    },
  );
}

// Usage in model:
@RdfGlobalResource(
  SchemaBook.classIri,
  iriStrategy: IriStrategy('{baseUri}/{version}/books/{isbn}'),
)
class Book {
  @RdfIriPart()
  final String isbn;
  // ...
}
```

## Polymorphic Types

### Interface-Based Polymorphism

```dart
abstract class Shape {
  double get area;
}

@RdfGlobalResource(SchemaCircle.classIri)
class Circle implements Shape {
  @RdfProperty(SchemaCircle.radius)
  final double radius;
  
  @override
  double get area => 3.14159 * radius * radius;
  // ...
}

@RdfGlobalResource(SchemaRectangle.classIri)
class Rectangle implements Shape {
  @RdfProperty(SchemaRectangle.width)
  final double width;
  
  @RdfProperty(SchemaRectangle.height)
  final double height;
  
  @override
  double get area => width * height;
  // ...
}

// Register with type discriminator
mapper.registerPolymorphic<Shape>(
  (typeIri) {
    switch (typeIri) {
      case SchemaCircle.classIri:
        return CircleMapper();
      case SchemaRectangle.classIri:
        return RectangleMapper();
      default:
        throw ArgumentError('Unknown shape type: $typeIri');
    }
  },
);
```

### Discriminator Property

```dart
@RdfGlobalResource(
  SchemaShape.classIri,
  discriminatorProperty: SchemaShape.type,
)
abstract class Shape {
  @RdfProperty(SchemaShape.type)
  IriTerm get type;
  
  double get area;
}
```

## Custom Validation

### Property Validation

```dart
class User {
  @RdfProperty(SchemaPerson.email)
  String _email = '';
  
  String get email => _email;
  
  set email(String value) {
    if (!_isValidEmail(value)) {
      throw ArgumentError('Invalid email address');
    }
    _email = value;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

### Cross-Field Validation

```dart
@RdfGlobalResource(SchemaEvent.classIri)
class Event {
  @RdfProperty(SchemaEvent.startTime)
  final DateTime startTime;
  
  @RdfProperty(SchemaEvent.endTime)
  final DateTime endTime;
  
  Event({
    required this.startTime,
    required this.endTime,
  }) {
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('End time must be after start time');
    }
  }
}
```

## Versioning and Evolution

### Backward Compatibility

```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  // Old IRI pattern for backward compatibility
  iriStrategy: IriStrategy([
    'http://example.org/v2/books/{isbn}',
    'http://example.org/v1/books/{isbn}',
  ]),
)
class Book {
  // New required field with default for old data
  @RdfProperty(SchemaBook.edition, defaultValue: 1)
  final int edition;
  
  // Renamed field with alias
  @RdfProperty(SchemaBook.title, aliases: [
    IriTerm('http://example.org/ns#legacyTitle'),
  ])
  final String title;
  
  // ...
}
```

### Schema Migration

```dart
class BookMapper implements GlobalResourceMapper<Book> {
  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    
    // Handle legacy data
    final title = reader.get<String>([
      SchemaBook.title,
      IriTerm('http://example.org/ns#legacyTitle'),
    ]);
    
    return Book(
      title: title ?? 'Untitled',
      // ... other fields
    );
  }
  
  // ...
}
```

## Performance Optimization

### Caching Strategies

```dart
class CachingMapper<T> implements ResourceMapper<T> {
  final ResourceMapper<T> _delegate;
  final Map<String, T> _cache = {};
  
  CachingMapper(this._delegate);
  
  @override
  T fromRdfResource(RdfSubject subject, DeserializationContext context) {
    final cacheKey = '${subject.runtimeType}:${subject.toString()}';
    return _cache.putIfAbsent(cacheKey, () {
      return _delegate.fromRdfResource(subject, context);
    });
  }
  
  // ...
}
```

### Lazy Loading

```dart
class LazyResource<T> {
  final IriTerm _iri;
  final RdfMapper _mapper;
  T? _value;
  bool _loaded = false;
  
  LazyResource(this._iri, this._mapper);
  
  T get value {
    if (!_loaded) {
      _value = _mapper.decode<T>(_iri);
      _loaded = true;
    }
    return _value!;
  }
}
```

## Security Considerations

### IRI Validation

```dart
class SafeIriMapper implements IriTermMapper<Uri> {
  final List<Pattern> _allowedPatterns;
  
  SafeIriMapper(this._allowedPatterns);
  
  @override
  IriTerm toRdfTerm(Uri uri, SerializationContext context) {
    _validateUri(uri);
    return IriTerm(uri.toString());
  }
  
  @override
  Uri fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = Uri.parse(term.iri);
    _validateUri(uri);
    return uri;
  }
  
  void _validateUri(Uri uri) {
    if (!_allowedPatterns.any((p) => p.hasMatch(uri.toString()))) {
      throw ArgumentError('URI not allowed: $uri');
    }
  }
}
```

### Input Sanitization

```dart
class SanitizingStringMapper implements LiteralTermMapper<String> {
  final RegExp _allowedChars;
  
  SanitizingStringMapper({String pattern = r'[^\w\s-]'}) 
    : _allowedChars = RegExp(pattern, unicode: true);
  
  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm(_sanitize(value));
  }
  
  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return _sanitize(term.value);
  }
  
  String _sanitize(String input) {
    return input.replaceAll(_allowedChars, '').trim();
  }
}
```

## Testing Strategies

### Unit Testing Mappers

```dart
void main() {
  late BookMapper mapper;
  
  setUp(() {
    mapper = BookMapper();
  });
  
  test('maps book to RDF and back', () {
    final book = Book(
      isbn: '1234567890',
      title: 'Test Book',
      // ...
    );
    
    // Serialize
    final (subject, triples) = mapper.toRdfResource(
      book, 
      SerializationContext(),
    );
    
    // Deserialize
    final deserialized = mapper.fromRdfResource(
      subject as IriTerm,
      DeserializationContext(triples: triples),
    );
    
    expect(deserialized.isbn, equals(book.isbn));
    expect(deserialized.title, equals(book.title));
    // ...
  });
}
```

### Property-Based Testing

```dart
void main() {
  final mapper = BookMapper();
  
  // Using the 'test' and 'property' packages
  property('round-trip serialization', () {
    // Generate random book data
    final book = BookFaker().generate();
    
    // Round-trip
    final (subject, triples) = mapper.toRdfResource(
      book, 
      SerializationContext(),
    );
    final deserialized = mapper.fromRdfResource(
      subject as IriTerm,
      DeserializationContext(triples: triples),
    );
    
    // Verify
    expect(deserialized, equals(book));
  });
}
```

## Debugging Generated Code

### Enabling Debug Logging

```dart
void main() {
  final mapper = RdfMapper(
    debug: true,  // Enable debug logging
    logger: (level, message, {error, stackTrace}) {
      // Custom logging
      print('[$level] $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    },
  );
  
  // ...
}
```

### Inspecting Generated Mappers

1. **View Generated Code**
   - Look in the `.dart_tool/build` directory
   - Search for files matching `*.mapper.g.dart`

2. **Add Debug Annotations**
   ```dart
   @RdfGlobalResource(
     SchemaBook.classIri,
     debug: true,  // Enable debug information
   )
   class Book { ... }
   ```

## Extending the Generator

### Custom Builder

```dart
class CustomBuilder extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // 1. Find all annotated elements
    final resolver = buildStep.resolver;
    final lib = await buildStep.inputLibrary;
    
    // 2. Process annotations
    final annotatedElements = ...;
    
    // 3. Generate code
    final generated = generateCode(annotatedElements);
    
    // 4. Write output
    final outputId = buildStep.allowedOutputs.single;
    await buildStep.writeAsString(outputId, generated);
  }
  
  // ...
}
```

### Plugin System

```dart
abstract class RdfMapperPlugin {
  /// Called during mapper generation
  void onGenerate(GenerationContext context) {}
  
  /// Called during mapper initialization
  void onInit(InitializationContext context) {}
}

// Example plugin
class ValidationPlugin extends RdfMapperPlugin {
  @override
  void onGenerate(GenerationContext context) {
    // Add validation code to generated mappers
    context.addCode("""
      if (value == null) {
        throw ArgumentError.notNull('value');
      }
    """);
  }
}
```

## Best Practices

1. **Consistent Naming**
   - Use clear, descriptive names for properties and classes
   - Follow Dart naming conventions
   - Be consistent with RDF predicate naming

2. **Documentation**
   - Document all public APIs
   - Include examples in doc comments
   - Document any constraints or requirements

3. **Error Handling**
   - Use specific exception types
   - Include helpful error messages
   - Handle edge cases gracefully

4. **Testing**
   - Test all mappers thoroughly
   - Include edge cases in tests
   - Test serialization round-trips

5. **Performance**
   - Optimize for the common case
   - Use efficient data structures
   - Consider caching for expensive operations

6. **Security**
   - Validate all inputs
   - Sanitize output when necessary
   - Be careful with dynamic IRI generation

7. **Maintainability**
   - Keep mappers focused and single-purpose
   - Reuse common patterns
   - Keep generated code clean and readable
