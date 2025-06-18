import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

@RdfIri('http://example.org/books/{isbn}')
class IriWithOnePart {
  @RdfIriPart()
  final String isbn;

  IriWithOnePart({
    required this.isbn,
  });
}

@RdfIri('http://example.org/books/{isbn}', true)
class IriWithOnePartExplicitlyGlobal {
  @RdfIriPart()
  final String isbn;

  IriWithOnePartExplicitlyGlobal({
    required this.isbn,
  });
}

@RdfIri('http://example.org/books/{isbn}')
class IriWithOnePartNamed {
  @RdfIriPart('isbn')
  final String value;

  IriWithOnePartNamed({
    required this.value,
  });
}

@RdfIri('http://example.org/{type}/{value}')
class IriWithTwoParts {
  @RdfIriPart()
  final String value;
  @RdfIriPart()
  final String type;
  IriWithTwoParts({
    required this.value,
    required this.type,
  });
}

@RdfIri('{+baseUri}/{type}/{value}')
class IriWithBaseUriAndTwoParts {
  @RdfIriPart()
  final String value;
  @RdfIriPart('type')
  final String otherPart;
  IriWithBaseUriAndTwoParts({
    required this.value,
    required this.otherPart,
  });
}

@RdfIri('{+baseUri}/books/{isbn}')
class IriWithBaseUri {
  @RdfIriPart()
  final String isbn;
  IriWithBaseUri({
    required this.isbn,
  });
}

@RdfIri('{+baseUri}/books/{isbn}', false)
class IriWithBaseUriNoGlobal {
  @RdfIriPart()
  final String isbn;
  IriWithBaseUriNoGlobal({
    required this.isbn,
  });
}

@RdfIri.namedMapper('testIriMapper')
class IriWithNamedMapper {
  final String value;

  IriWithNamedMapper(this.value);
}

@RdfIri.mapper(TestIriMapper)
class IriWithMapper {
  final String value;

  IriWithMapper(this.value);
}

@RdfIri.mapperInstance(TestIriMapper2())
class IriWithMapperInstance {
  final String value;

  IriWithMapperInstance(this.value);
}

class TestIriMapper implements IriTermMapper<IriWithMapper> {
  const TestIriMapper();

  @override
  IriWithMapper fromRdfTerm(IriTerm term, DeserializationContext context) {
    return IriWithMapper(term.iri);
  }

  @override
  IriTerm toRdfTerm(IriWithMapper value, SerializationContext context) {
    return IriTerm(value.value);
  }
}

class TestIriMapper2 implements IriTermMapper<IriWithMapperInstance> {
  const TestIriMapper2();

  @override
  IriWithMapperInstance fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    return IriWithMapperInstance(term.iri);
  }

  @override
  IriTerm toRdfTerm(IriWithMapperInstance value, SerializationContext context) {
    return IriTerm(value.value);
  }
}
