import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('http://example.org/books/{isbn}'),
  registerGlobally: true,
)
class Book {
  @RdfIriPart()
  final String isbn;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author,
      iri: IriMapping('http://example.org/authors/{authorId}'))
  final String authorId;

  Book({
    required this.isbn,
    required this.title,
    required this.authorId,
  });
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy())
class Person {
  @RdfIriPart()
  final String id;

  Person({required this.id});
}

// This class is not annotated with @RdfGlobalResource
class NotAnnotated {
  final String name;

  NotAnnotated(this.name);
}
