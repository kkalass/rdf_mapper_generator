import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_core/src/graph/triple.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
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
class ClassWithEmptyIriStrategy {}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy(),
    registerGlobally: false)
class ClassWithEmptyIriStrategyNoRegisterGlobally {}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy('http://example.org/persons/{id}'))
class ClassWithIriTemplateStrategy {
  @RdfIriPart()
  final String id;

  ClassWithIriTemplateStrategy({required this.id});
}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy('{baseUri}/persons/{thisId}'))
class ClassWithIriTemplateAndContextVariableStrategy {
  @RdfIriPart('thisId')
  final String id;

  ClassWithIriTemplateAndContextVariableStrategy({required this.id});
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.namedMapper('testMapper'))
class ClassWithIriNamedMapperStrategy {}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.mapper(TestIriMapper))
class ClassWithIriMapperStrategy {}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy.mapperInstance(TestIriMapper()))
class ClassWithIriMapperInstanceStrategy {}

@RdfGlobalResource.namedMapper('testGlobalResourceMapper')
class ClassWithMapperNamedMapperStrategy {}

@RdfGlobalResource.mapper(TestGlobalResourceMapper)
class ClassWithMapperStrategy {}

@RdfGlobalResource.mapperInstance(TestGlobalResourceMapper())
class ClassWithMapperInstanceStrategy {}

class TestGlobalResourceMapper implements GlobalResourceMapper {
  const TestGlobalResourceMapper();

  @override
  fromRdfResource(IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri => throw UnimplementedError();
}

class TestIriMapper implements IriTermMapper {
  const TestIriMapper();

  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(value, SerializationContext context) {
    throw UnimplementedError();
  }
}

// This class is not annotated with @RdfGlobalResource
class NotAnnotated {
  final String name;

  NotAnnotated(this.name);
}
