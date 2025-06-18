import 'package:rdf_core/src/graph/rdf_term.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

import '../fixtures/global_resource_processor_test_models.dart' as grptm;
import '../init_test_rdf_mapper.g.dart';

class TestMapper
    implements IriTermMapper<grptm.ClassWithIriNamedMapperStrategy> {
  @override
  grptm.ClassWithIriNamedMapperStrategy fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(grptm.ClassWithIriNamedMapperStrategy value,
      SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return IriTerm('http://example.org/persons3/${value.hashCode}');
  }
}

const baseUri = 'http://example.org/';

RdfMapper defaultInitTestRdfMapper({
  RdfMapper? rdfMapper,
  // Provider parameters
  String Function()? baseUriProvider,
  // IRI mapper parameters
  IriTermMapper<grptm.ClassWithIriNamedMapperStrategy>? testMapper,
}) {
  return initTestRdfMapper(
      baseUriProvider: baseUriProvider ?? (() => baseUri),
      testMapper: testMapper ?? TestMapper());
}
