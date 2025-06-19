import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

import '../fixtures/global_resource_processor_test_models.dart' as grptm;
import '../fixtures/local_resource_processor_test_models.dart' as lrptm;
import '../fixtures/iri_processor_test_models.dart' as iptm;
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

class NamedTestGlobalResourceMapper
    implements GlobalResourceMapper<grptm.ClassWithMapperNamedMapperStrategy> {
  const NamedTestGlobalResourceMapper();

  @override
  grptm.ClassWithMapperNamedMapperStrategy fromRdfResource(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
      grptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri =>
      IriTerm('http://example.org/g/ClassWithMapperNamedMapperStrategy');
}

class NamedTestLocalResourceMapper
    implements LocalResourceMapper<lrptm.ClassWithMapperNamedMapperStrategy> {
  const NamedTestLocalResourceMapper();

  @override
  lrptm.ClassWithMapperNamedMapperStrategy fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      lrptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri =>
      IriTerm('http://example.org/l/ClassWithMapperNamedMapperStrategy');
}

class NamedTestIriMapper implements IriTermMapper<iptm.IriWithNamedMapper> {
  const NamedTestIriMapper();

  @override
  iptm.IriWithNamedMapper fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    return iptm.IriWithNamedMapper(term.iri);
  }

  @override
  IriTerm toRdfTerm(
      iptm.IriWithNamedMapper value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return IriTerm(value.value);
  }
}

const baseUri = 'http://example.org';

RdfMapper defaultInitTestRdfMapper({
  RdfMapper? rdfMapper,
  // Provider parameters
  String Function()? baseUriProvider,
  // IRI mapper parameters
  IriTermMapper<grptm.ClassWithIriNamedMapperStrategy>? testMapper,
  GlobalResourceMapper<grptm.ClassWithMapperNamedMapperStrategy>?
      testGlobalResourceMapper,
  LocalResourceMapper<lrptm.ClassWithMapperNamedMapperStrategy>?
      testLocalResourceMapper,
  IriTermMapper<iptm.IriWithNamedMapper>? testIriMapper,
}) {
  return initTestRdfMapper(
    baseUriProvider: baseUriProvider ?? (() => baseUri),
    testMapper: testMapper ?? TestMapper(),
    testGlobalResourceMapper:
        testGlobalResourceMapper ?? NamedTestGlobalResourceMapper(),
    testLocalResourceMapper:
        testLocalResourceMapper ?? NamedTestLocalResourceMapper(),
    testIriMapper: testIriMapper ?? NamedTestIriMapper(),
  );
}
