import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
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

class OptionalPropertyTest {
  @RdfProperty(SchemaBook.name, include: false)
  final String name;

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

class CollectionTest {
  @RdfProperty(SchemaBook.author, collection: RdfCollectionType.none)
  final List<String> authors;

  CollectionTest({required this.authors});
}

class MapTest {
  @RdfProperty(SchemaBook.reviews, collection: RdfCollectionType.none)
  final Map<String, String> reviews;

  MapTest({required this.reviews});
}

class SetTest {
  @RdfProperty(SchemaBook.keywords, collection: RdfCollectionType.none)
  final Set<String> keywords;

  SetTest({required this.keywords});
}

class ComplexTypeTest {
  @RdfProperty(SchemaBook.bookFormat)
  final BookFormatType format;

  ComplexTypeTest({required this.format});
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
