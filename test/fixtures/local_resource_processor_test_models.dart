import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfLocalResource(
  SchemaBook.classIri,
)
class Book {
  @RdfProperty(SchemaBook.isbn)
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

@RdfLocalResource(SchemaPerson.classIri, false)
class ClassNoRegisterGlobally {
  @RdfProperty(SchemaPerson.name)
  final String name;

  ClassNoRegisterGlobally({required this.name});
}

@RdfLocalResource.namedMapper('testLocalResourceMapper')
class ClassWithMapperNamedMapperStrategy {}

@RdfLocalResource.mapper(TestLocalResourceMapper)
class ClassWithMapperStrategy {}

@RdfLocalResource.mapperInstance(TestLocalResourceMapper2())
class ClassWithMapperInstanceStrategy {}

class TestLocalResourceMapper
    implements LocalResourceMapper<ClassWithMapperStrategy> {
  const TestLocalResourceMapper();

  @override
  fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri =>
      IriTerm('http://example.org/l/ClassWithMapperStrategy');
}

class TestLocalResourceMapper2
    implements LocalResourceMapper<ClassWithMapperInstanceStrategy> {
  const TestLocalResourceMapper2();

  @override
  fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri => IriTerm(
        'http://example.org/l/ClassWithMapperInstanceStrategy',
      );
}
