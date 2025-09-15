// Test fixtures for annotation subclassing functionality
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

// Custom annotation that extends RdfGlobalResource
class CustomGlobalResource extends RdfGlobalResource {
  const CustomGlobalResource(
    IriTerm classIri, [
    IriStrategy iriStrategy = const IriStrategy('https://example.com/{id}'),
  ]) : super(classIri, iriStrategy);
}

// Another custom annotation with specific configuration
class PodResource extends RdfGlobalResource {
  const PodResource.twoDigits(IriTerm classIri)
      : super(
          classIri,
          const IriStrategy('https://pod.example.com/{id}'),
          registerGlobally: true,
        );
}

// Custom property annotation
class CustomProperty extends RdfProperty {
  const CustomProperty(IriTerm propertyIri) : super(propertyIri);
}

// Test models using custom annotations
@CustomGlobalResource(SchemaBook.classIri)
class BookWithCustomAnnotation {
  @RdfIriPart()
  final String id;

  @CustomProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  BookWithCustomAnnotation({
    required this.id,
    required this.title,
    required this.author,
  });
}

@PodResource.twoDigits(SchemaPerson.classIri)
class PersonWithPodResource {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaPerson.name)
  final String name;

  PersonWithPodResource({
    required this.id,
    required this.name,
  });
}

// Test model using regular annotation for comparison
@RdfGlobalResource(
  SchemaArticle.classIri,
  IriStrategy('https://example.com/articles/{id}'),
)
class ArticleWithRegularAnnotation {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaArticle.name)
  final String title;

  ArticleWithRegularAnnotation({
    required this.id,
    required this.title,
  });
}