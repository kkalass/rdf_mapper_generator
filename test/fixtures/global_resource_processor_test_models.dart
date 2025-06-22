import 'package:rdf_core/rdf_core.dart';
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
class ClassWithEmptyIriStrategy {
  @RdfIriPart()
  final String iri;

  ClassWithEmptyIriStrategy({required this.iri});
}

@RdfGlobalResource(null, IriStrategy())
class ClassWithNoRdfType {
  @RdfIriPart()
  late final String iri;

  @RdfProperty(SchemaPerson.name)
  final String name;

  @RdfProperty(SchemaPerson.foafAge)
  final int? age;

  ClassWithNoRdfType(this.name, {this.age});
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy(),
    registerGlobally: false)
class ClassWithEmptyIriStrategyNoRegisterGlobally {
  @RdfIriPart()
  final String iri;

  ClassWithEmptyIriStrategyNoRegisterGlobally({required this.iri});
}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy('http://example.org/persons/{id}'))
class ClassWithIriTemplateStrategy {
  @RdfIriPart()
  final String id;

  ClassWithIriTemplateStrategy({required this.id});
}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy('{+baseUri}/persons/{thisId}'))
class ClassWithIriTemplateAndContextVariableStrategy {
  @RdfIriPart('thisId')
  final String id;

  ClassWithIriTemplateAndContextVariableStrategy({required this.id});
}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy('{+otherBaseUri}/persons/{thisId}'),
    registerGlobally: false)
class ClassWithOtherBaseUriNonGlobal {
  @RdfIriPart('thisId')
  final String id;

  ClassWithOtherBaseUriNonGlobal({required this.id});
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.namedMapper('testMapper'))
class ClassWithIriNamedMapperStrategy {}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.mapper(TestIriMapper))
class ClassWithIriMapperStrategy {}

@RdfGlobalResource(
    SchemaPerson.classIri, IriStrategy.mapperInstance(TestIriMapper2()))
class ClassWithIriMapperInstanceStrategy {}

@RdfGlobalResource.namedMapper('testGlobalResourceMapper')
class ClassWithMapperNamedMapperStrategy {}

@RdfGlobalResource.mapper(TestGlobalResourceMapper)
class ClassWithMapperStrategy {}

@RdfGlobalResource.mapperInstance(TestGlobalResourceMapper2())
class ClassWithMapperInstanceStrategy {}

class TestGlobalResourceMapper
    implements GlobalResourceMapper<ClassWithMapperStrategy> {
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
  IriTerm? get typeIri =>
      IriTerm('http://example.org/g/ClassWithMapperStrategy');
}

class TestGlobalResourceMapper2
    implements GlobalResourceMapper<ClassWithMapperInstanceStrategy> {
  const TestGlobalResourceMapper2();

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
  IriTerm? get typeIri => IriTerm(
        'http://example.org/g/ClassWithMapperInstanceStrategy',
      );
}

class TestIriMapper implements IriTermMapper<ClassWithIriMapperStrategy> {
  const TestIriMapper();

  @override
  ClassWithIriMapperStrategy fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return IriTerm('http://example.org/persons/${value.hashCode}');
  }
}

class TestIriMapper2
    implements IriTermMapper<ClassWithIriMapperInstanceStrategy> {
  const TestIriMapper2();

  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return IriTerm('http://example.org/persons2/${value.hashCode}');
  }
}

// This class is not annotated with @RdfGlobalResource
class NotAnnotated {
  final String name;

  NotAnnotated(this.name);
}
