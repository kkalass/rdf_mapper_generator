import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

// A sample mapper class for testing
class TestMapper implements IriTermMapper<Map<String, dynamic>> {
  final String prefix;

  const TestMapper({required this.prefix});

  IriTerm call(Map<String, dynamic> properties) {
    return IriTerm('$prefix/${properties['id']}');
  }

  @override
  IriTerm toRdfTerm(
      Map<String, dynamic> properties, SerializationContext context) {
    return call(properties);
  }

  @override
  Map<String, dynamic> fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    // This is a simplified implementation for testing
    return {'id': term.iri.split('/').last};
  }
}

// A test class with all possible annotation parameters
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy.mapperInstance(
      const TestMapper(prefix: 'https://example.org/books')),
  registerGlobally: true,
)
class BookWithMapper {
  @RdfIriPart()
  final String id;

  @RdfProperty(
    SchemaBook.name,
    include: true,
    includeDefaultsInSerialization: false,
    defaultValue: 'Untitled',
    iri: IriMapping('https://example.org/books/{id}/title'),
  )
  final String title;

  BookWithMapper({
    required this.id,
    required this.title,
  });
}

// A test class with mapper instance
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy.mapperInstance(
      const TestMapper(prefix: 'https://example.org/books')),
  registerGlobally: false,
)
class BookWithMapperInstance {
  @RdfIriPart()
  final String id;

  BookWithMapperInstance(this.id);
}

// A test class with template strategy
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithTemplate {
  @RdfIriPart()
  final String id;

  BookWithTemplate(this.id);
}
