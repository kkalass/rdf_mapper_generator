import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_vocabularies/schema.dart';
import 'package:rdf_vocabularies/xsd.dart';

// Helper function for comparing maps in == operator
bool mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) {
      return false;
    }
  }
  return true;
}

class SimplePropertyTest {
  @RdfProperty(SchemaBook.name)
  final String name;

  SimplePropertyTest({required this.name});
}

class DeserializationOnlyPropertyTest {
  @RdfProperty(SchemaBook.name, include: false)
  final String name;

  DeserializationOnlyPropertyTest({required this.name});
}

class OptionalPropertyTest {
  @RdfProperty(SchemaBook.name)
  final String? name;

  OptionalPropertyTest({required this.name});
}

class DefaultValueTest {
  @RdfProperty(SchemaBook.isbn, defaultValue: 'default-isbn')
  final String isbn;

  DefaultValueTest({required this.isbn});
}

class IncludeDefaultsTest {
  @RdfProperty(
    SchemaBook.numberOfPages,
    defaultValue: 5,
    includeDefaultsInSerialization: true,
  )
  final int rating;

  IncludeDefaultsTest({required this.rating});
}

class IriMappingTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/authors/{authorId}'),
  )
  final String authorId;

  IriMappingTest({required this.authorId});
}

class IriMappingNamedMapperTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping.namedMapper('iriMapper'),
  )
  final String authorId;

  IriMappingNamedMapperTest({required this.authorId});
}

class IriMappingMapperTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping.mapper(IriMapperImpl),
  )
  final String authorId;

  IriMappingMapperTest({required this.authorId});
}

class IriMappingMapperInstanceTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping.mapperInstance(IriMapperImpl()),
  )
  final String authorId;

  IriMappingMapperInstanceTest({required this.authorId});
}

class IriMapperImpl implements IriTermMapper<IriMappingTest> {
  const IriMapperImpl();

  @override
  IriMappingTest fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(IriMappingTest value, SerializationContext context) {
    // Implementation here
    throw UnimplementedError();
  }
}

class LocalResourceMappingTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.namedMapper('testLocalMapper'),
  )
  final Object author;

  LocalResourceMappingTest({required this.author});
}

class GlobalResourceMappingTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.namedMapper('testGlobalMapper'),
  )
  final Object publisher;

  GlobalResourceMappingTest({required this.publisher});
}

class LiteralMappingTest {
  @RdfProperty(
    SchemaBook.bookFormat,
    literal: LiteralMapping.namedMapper('testLiteralMapper'),
  )
  final double price;

  LiteralMappingTest({required this.price});
}

class CollectionNoneTest {
  @RdfProperty(SchemaBook.author, collection: RdfCollectionType.none)
  final List<String> authors;

  CollectionNoneTest({required this.authors});
}

class CollectionAutoTest {
  @RdfProperty(SchemaBook.author, collection: RdfCollectionType.auto)
  final List<String> authors;

  CollectionAutoTest({required this.authors});
}

class CollectionTest {
  @RdfProperty(SchemaBook.author)
  final List<String> authors;

  CollectionTest({required this.authors});
}

class MapNoCollectionTest {
  @RdfProperty(SchemaBook.reviews, collection: RdfCollectionType.none)
  final Map<String, String> reviews;

  MapNoCollectionTest({required this.reviews});
}

class MapLocalResourceMapperTest {
  @RdfProperty(
    SchemaBook.reviews,
    localResource: LocalResourceMapping.namedMapper("mapEntryMapper"),
  )
  final Map<String, String> reviews;

  MapLocalResourceMapperTest({required this.reviews});
}

class SetTest {
  @RdfProperty(SchemaBook.keywords)
  final Set<String> keywords;

  SetTest({required this.keywords});
}

class EnumTypeTest {
  @RdfProperty(SchemaBook.bookFormat)
  final BookFormatType format;

  EnumTypeTest({required this.format});
}

enum BookFormatType { hardcover, paperback, ebook, audioBook }

class ComplexDefaultValueTest {
  @RdfProperty(
    SchemaBook.isbn,
    defaultValue: const {'id': '1', 'name': 'Test'},
  )
  final Map<String, dynamic> complexValue;

  ComplexDefaultValueTest({required this.complexValue});
}

class LatePropertyTest {
  @RdfProperty(SchemaBook.name)
  late String name;

  @RdfProperty(SchemaBook.description)
  late String? description;

  LatePropertyTest();
}

class MutablePropertyTest {
  @RdfProperty(SchemaBook.name)
  String name;

  @RdfProperty(SchemaBook.description)
  String? description;

  MutablePropertyTest({required this.name, this.description});
}

class LanguageTagTest {
  @RdfProperty(
    SchemaBook.description,
    literal: const LiteralMapping.withLanguage('en'),
  )
  final String description;

  LanguageTagTest({required this.description});
}

class DatatypeTest {
  @RdfProperty(
    SchemaBook.dateCreated,
    literal: const LiteralMapping.withType(Xsd.dateTime),
  )
  final DateTime date;

  DatatypeTest({required this.date});
}

class NoAnnotationTest {
  final String name;
  NoAnnotationTest({required this.name});
}

/// Test model for named mappers
class GlobalResourceNamedMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.namedMapper('testNamedMapper'),
  )
  final Object publisher;

  const GlobalResourceNamedMapperTest({required this.publisher});
}

/// Test model for custom mapper with parameters
class LiteralNamedMapperTest {
  @RdfProperty(
    SchemaBook.isbn,
    literal: LiteralMapping.namedMapper('testCustomMapper'),
  )
  final String isbn;

  const LiteralNamedMapperTest({required this.isbn});
}

/// Test model for type-based mappers
class LiteralTypeMapperTest {
  @RdfProperty(
    SchemaBook.bookFormat,
    literal: LiteralMapping.mapper(LiteralMapperImpl),
  )
  final double price;

  const LiteralTypeMapperTest({required this.price});
}

/// Test model for type-based mappers using mapper() constructor
class GlobalResourceTypeMapperTest {
  @RdfProperty(
    SchemaBook.bookFormat,
    globalResource: GlobalResourceMapping.mapper(GlobalResourceMapperImpl),
  )
  final Object format;

  const GlobalResourceTypeMapperTest({required this.format});
}

// Example implementation of GlobalResourceMapper
class GlobalResourceMapperImpl
    implements GlobalResourceMapper<GlobalResourceMapperTest> {
  const GlobalResourceMapperImpl();
  @override
  GlobalResourceMapperTest fromRdfResource(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
      GlobalResourceMapperTest value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri => throw UnimplementedError();
}

// Example implementation of LocalResourceMapper
class LocalResourceMapperImpl
    implements LocalResourceMapper<LocalResourceMapperTest> {
  const LocalResourceMapperImpl();
  @override
  LocalResourceMapperTest fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      LocalResourceMapperTest value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri => throw UnimplementedError();
}

// Example implementation of LiteralTermMapper
class LiteralMapperImpl implements LiteralTermMapper<LiteralMapperTest> {
  const LiteralMapperImpl();

  @override
  LiteralMapperTest fromRdfTerm(
      LiteralTerm term, DeserializationContext context) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  LiteralTerm toRdfTerm(LiteralMapperTest value, SerializationContext context) {
    // Implementation here
    throw UnimplementedError();
  }
}

/// Test model for global resource mapper using mapper() constructor
class GlobalResourceMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.mapper(GlobalResourceMapperImpl),
  )
  final Object publisher;

  const GlobalResourceMapperTest({required this.publisher});
}

/// Test model for global resource mapper using mapperInstance() constructor
class GlobalResourceInstanceMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource:
        GlobalResourceMapping.mapperInstance(GlobalResourceMapperImpl()),
  )
  final Object publisher;

  const GlobalResourceInstanceMapperTest({required this.publisher});
}

/// Test model for local resource mapper using mapper() constructor
class LocalResourceMapperTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.mapper(LocalResourceMapperImpl),
  )
  final Object author;

  const LocalResourceMapperTest({required this.author});
}

/// Test model for local resource mapper using mapperInstance() constructor
class LocalResourceInstanceMapperTest {
  @RdfProperty(
    SchemaBook.author,
    localResource:
        LocalResourceMapping.mapperInstance(LocalResourceMapperImpl()),
  )
  final Object author;

  const LocalResourceInstanceMapperTest({required this.author});
}

/// Test model for literal mapper using mapper() constructor
class LiteralMapperTest {
  @RdfProperty(
    SchemaBook.numberOfPages,
    literal: LiteralMapping.mapper(LiteralMapperImpl),
  )
  final int pageCount;

  const LiteralMapperTest({required this.pageCount});
}

/// Test model for literal mapper using mapperInstance() constructor
class LiteralInstanceMapperTest {
  @RdfProperty(
    SchemaBook.isbn,
    literal: LiteralMapping.mapperInstance(const LiteralMapperImpl()),
  )
  final String isbn;

  const LiteralInstanceMapperTest({required this.isbn});
}
