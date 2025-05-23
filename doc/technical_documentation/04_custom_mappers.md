# Custom Mappers

This document explains how to create and use custom mappers for advanced RDF mapping scenarios.

## Table of Contents

1. [Introduction to Custom Mappers](#introduction-to-custom-mappers)
2. [Mapper Interfaces](#mapper-interfaces)
   - [LiteralTermMapper](#literaltermmapper)
   - [IriTermMapper](#iritermmapper)
   - [ResourceMapper](#resourcemapper)
3. [Creating Custom Mappers](#creating-custom-mappers)
   - [Simple Value Mapper](#simple-value-mapper)
   - [Complex Object Mapper](#complex-object-mapper)
   - [Collection Mapper](#collection-mapper)
4. [Registering Custom Mappers](#registering-custom-mappers)
5. [Mapper Factories](#mapper-factories)
6. [Advanced Topics](#advanced-topics)
   - [Context-Aware Mappers](#context-aware-mappers)
   - [Dependency Injection](#dependency-injection)
   - [Caching Strategies](#caching-strategies)
7. [Performance Considerations](#performance-considerations)
8. [Testing Custom Mappers](#testing-custom-mappers)

## Introduction to Custom Mappers

Custom mappers allow you to define how specific Dart types are serialized to and deserialized from RDF. They are useful when:

- The default mapping behavior is insufficient
- You need special handling for certain data types
- You want to optimize serialization/deserialization
- You need to work with legacy data formats

## Mapper Interfaces

### LiteralTermMapper

Maps between Dart objects and RDF literal terms.

```dart
abstract class LiteralTermMapper<T> {
  /// Converts a Dart value to an RDF literal term.
  LiteralTerm toRdfTerm(T value, SerializationContext context);
  
  /// Converts an RDF literal term to a Dart value.
  T fromRdfTerm(LiteralTerm term, DeserializationContext context);
}
```

### IriTermMapper

Maps between Dart objects and RDF IRI terms.

```dart
abstract class IriTermMapper<T> {
  /// Converts a Dart value to an RDF IRI term.
  IriTerm toRdfTerm(T value, SerializationContext context);
  
  /// Converts an RDF IRI term to a Dart value.
  T fromRdfTerm(IriTerm term, DeserializationContext context);
}
```

### ResourceMapper

Base interface for mappers that handle RDF resources.

```dart
abstract class ResourceMapper<T> {
  /// The RDF type IRI for the mapped resource.
  IriTerm get typeIri;
  
  /// Converts an RDF resource to a Dart object.
  T fromRdfResource(RdfSubject subject, DeserializationContext context);
  
  /// Converts a Dart object to an RDF resource.
  (RdfSubject, List<Triple>) toRdfResource(
    T value, 
    SerializationContext context, {
    RdfSubject? parentSubject,
  });
}
```

## Creating Custom Mappers

### Simple Value Mapper

Example: Mapping a custom `Email` type.

```dart
class Email {
  final String value;
  
  Email(this.value) {
    if (!_emailRegex.hasMatch(value)) {
      throw ArgumentError('Invalid email address: $value');
  }
  
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
}

class EmailMapper implements LiteralTermMapper<Email> {
  @override
  LiteralTerm toRdfTerm(Email email, SerializationContext context) {
    return LiteralTerm(
      email.value,
      datatype: IriTerm('http://www.w3.org/2001/XMLSchema#string'),
    );
  }
  
  @override
  Email fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return Email(term.value);
  }
}
```

### Complex Object Mapper

Example: Mapping a `Money` type with amount and currency.

```dart
class Money {
  final double amount;
  final String currency;
  
  Money(this.amount, this.currency);
  
  @override
  String toString() => '$amount $currency';
  
  static Money fromString(String value) {
    final parts = value.split(' ');
    if (parts.length != 2) {
      throw FormatException('Invalid money format: $value');
    }
    return Money(
      double.parse(parts[0]),
      parts[1],
    );
  }
}

class MoneyMapper implements LiteralTermMapper<Money> {
  @override
  LiteralTerm toRdfTerm(Money money, SerializationContext context) {
    return LiteralTerm(
      money.toString(),
      datatype: IriTerm('http://www.example.org/ns#money'),
    );
  }
  
  @override
  Money fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return Money.fromString(term.value);
  }
}
```

### Collection Mapper

Example: Mapping a custom collection type.

```dart
class StringList {
  final List<String> values;
  final String separator;
  
  StringList(this.values, {this.separator = ','});
  
  @override
  String toString() => values.join(separator);
  
  static StringList fromString(String value, {String separator = ','}) {
    return StringList(
      value.split(separator).map((s) => s.trim()).toList(),
      separator: separator,
    );
  }
}

class StringListMapper implements LiteralTermMapper<StringList> {
  final String separator;
  
  const StringListMapper({this.separator = ','});
  
  @override
  LiteralTerm toRdfTerm(StringList list, SerializationContext context) {
    return LiteralTerm(
      list.toString(),
      datatype: IriTerm('http://www.w3.org/2001/XMLSchema#string'),
    );
  }
  
  @override
  StringList fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return StringList.fromString(term.value, separator: separator);
  }
}
```

## Registering Custom Mappers

### Using Annotations

```dart
@RdfProperty(
  SchemaBook.tags,
  literal: LiteralMapping.mapperInstance(const StringListMapper(separator: '|')),
)
final StringList tags;
```

### Programmatic Registration

```dart
void main() {
  final mapper = RdfMapper();
  
  // Register custom mappers
  mapper.registerLiteralTerm<Email>(EmailMapper());
  mapper.registerLiteralTerm<Money>(MoneyMapper());
  mapper.registerLiteralTerm<StringList>(
    const StringListMapper(separator: '|'),
  );
  
  // Use the mapper...
}
```

## Mapper Factories

For more complex scenarios, you can use mapper factories:

```dart
class MapperFactory {
  final Map<Type, dynamic> _mappers = {};
  
  void register<T>(LiteralTermMapper<T> mapper) {
    _mappers[T] = mapper;
  }
  
  LiteralTermMapper<T>? getMapper<T>() {
    return _mappers[T] as LiteralTermMapper<T>?;
  }
  
  // Register all mappers
  void registerMappers() {
    register(EmailMapper());
    register(MoneyMapper());
    register(const StringListMapper(separator: '|'));
  }
}
```

## Advanced Topics

### Context-Aware Mappers

Mappers can access the serialization/deserialization context:

```dart
class ContextAwareMapper implements LiteralTermMapper<dynamic> {
  @override
  LiteralTerm toRdfTerm(dynamic value, SerializationContext context) {
    // Access context data
    final baseUri = context.baseUri;
    final options = context.options;
    
    // Implementation...
  }
  
  // ...
}
```

### Dependency Injection

For mappers that require dependencies:

```dart
class UserMapper implements ResourceMapper<User> {
  final UserRepository _userRepository;
  
  UserMapper(this._userRepository);
  
  // Implementation...
}

// Usage:
final userMapper = UserMapper(userRepository);
mapper.registerGlobalResource<User>(userMapper);
```

### Caching Strategies

Implement caching in custom mappers for better performance:

```dart
class CachingMapper implements LiteralTermMapper<ExpensiveToCreate> {
  final Map<String, ExpensiveToCreate> _cache = {};
  
  @override
  ExpensiveToCreate fromRdfTerm(LiteralTerm term, DeserializationContext context) {
    return _cache.putIfAbsent(term.value, () {
      // Expensive creation logic here
      return ExpensiveToCreate(term.value);
    });
  }
  
  // ...
}
```

## Performance Considerations

1. **Reuse Mapper Instances**
   - Create mappers once and reuse them
   - Register them at application startup

2. **Minimize Object Allocation**
   - Cache intermediate results when possible
   - Use const constructors where applicable

3. **Optimize for Common Cases**
   - Handle the most frequent cases first
   - Use efficient data structures

## Testing Custom Mappers

Test your custom mappers thoroughly:

```dart
void main() {
  final mapper = MoneyMapper();
  
  test('serializes money correctly', () {
    final money = Money(19.99, 'USD');
    final term = mapper.toRdfTerm(money, SerializationContext());
    expect(term.value, equals('19.99 USD'));
  });
  
  test('deserializes money correctly', () {
    final term = LiteralTerm('19.99 USD');
    final money = mapper.fromRdfTerm(term, DeserializationContext());
    expect(money.amount, equals(19.99));
    expect(money.currency, equals('USD'));
  });
  
  test('throws on invalid format', () {
    final term = LiteralTerm('invalid');
    expect(
      () => mapper.fromRdfTerm(term, DeserializationContext()),
      throwsFormatException,
    );
  });
}
```
