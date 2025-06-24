import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';

import '../fixtures/global_resource_processor_test_models.dart' as grptm;
import '../fixtures/local_resource_processor_test_models.dart' as lrptm;
import '../fixtures/iri_processor_test_models.dart' as iptm;
import '../fixtures/literal_processor_test_models.dart' as lptm;
import '../init_test_rdf_mapper.g.dart';

class TestMapper
    implements IriTermMapper<grptm.ClassWithIriNamedMapperStrategy> {
  const TestMapper();
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
    return grptm.ClassWithMapperNamedMapperStrategy();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
      grptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(IriTerm(
            'http://example.org/instance/ClassWithMapperNamedMapperStrategy'))
        .build();
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
    return lrptm.ClassWithMapperNamedMapperStrategy();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      lrptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
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

class NamedTestLiteralMapper
    implements LiteralTermMapper<lptm.LiteralWithNamedMapper> {
  const NamedTestLiteralMapper();

  @override
  lptm.LiteralWithNamedMapper fromRdfTerm(
      LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return lptm.LiteralWithNamedMapper(term.value);
  }

  @override
  LiteralTerm toRdfTerm(
      lptm.LiteralWithNamedMapper value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return LiteralTerm(value.value);
  }
}

/// IRI mapper for three part tuple with properties (String id, String surname, int version)
class TestMapper3PartsWithProperties
    implements IriTermMapper<(String, String, int)> {
  const TestMapper3PartsWithProperties();

  @override
  (String, String, int) fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    // Extract ID, surname, and version from IRI like http://example.org/3parts/test-id/smith/42
    final iri = term.iri;
    final match = RegExp(r'http://example\.org/3parts/([^/]+)/([^/]+)/(\d+)$')
        .firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid IRI format: $iri');
    }
    return (match.group(1)!, match.group(2)!, int.parse(match.group(3)!));
  }

  @override
  IriTerm toRdfTerm((String, String, int) value, SerializationContext context) {
    return IriTerm(
        'http://example.org/3parts/${value.$1}/${value.$2}/${value.$3}');
  }
}

/// Test IRI mapper for String values
class TestIriMapper implements IriTermMapper<String> {
  const TestIriMapper();

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.iri;
  }

  @override
  IriTerm toRdfTerm(String value, SerializationContext context) {
    return IriTerm(value);
  }
}

/// Test local resource mapper for `Map<String, String>` values
class TestMapEntryMapper implements LocalResourceMapper<Map<String, String>> {
  const TestMapEntryMapper();

  @override
  Map<String, String> fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    return {'id': term.toString()};
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      Map<String, String> value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
  }

  @override
  IriTerm? get typeIri => IriTerm('http://example.org/MapEntry');
}

/// Test literal mapper for String values (custom mapper)
class TestCustomMapper implements LiteralTermMapper<String> {
  const TestCustomMapper();

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value;
  }

  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm(value);
  }
}

/// Test global resource mapper for Object values
class TestGlobalMapper implements GlobalResourceMapper<Object> {
  const TestGlobalMapper();

  @override
  Object fromRdfResource(IriTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(
            IriTerm('http://example.org/objects/${value.hashCode}'))
        .build();
  }

  @override
  IriTerm? get typeIri => IriTerm('http://example.org/Object');
}

/// Test literal mapper for double values (price mapper)
class TestLiteralPriceMapper implements LiteralTermMapper<double> {
  const TestLiteralPriceMapper();

  @override
  double fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return double.parse(term.value);
  }

  @override
  LiteralTerm toRdfTerm(double value, SerializationContext context) {
    return LiteralTerm(value.toString());
  }
}

/// Test local resource mapper for Object values
class TestLocalMapper implements LocalResourceMapper<Object> {
  const TestLocalMapper();

  @override
  Object fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (BlankNodeTerm, List<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
  }

  @override
  IriTerm? get typeIri => IriTerm('http://example.org/LocalObject');
}

/// Test global resource mapper for Object values (named mapper)
class TestNamedMapper implements GlobalResourceMapper<Object> {
  const TestNamedMapper();

  @override
  Object fromRdfResource(IriTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (IriTerm, List<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(IriTerm('http://example.org/named/${value.hashCode}'))
        .build();
  }

  @override
  IriTerm? get typeIri => IriTerm('http://example.org/NamedObject');
}

const baseUri = 'http://example.org';

RdfMapper defaultInitTestRdfMapper(
    {RdfMapper? rdfMapper,
    // Provider parameters
    String Function()? baseUriProvider,
    // IRI mapper parameters
    IriTermMapper<String>? iriMapper,
    LocalResourceMapper<Map<String, String>>? mapEntryMapper,
    LiteralTermMapper<String>? testCustomMapper,
    GlobalResourceMapper<Object>? testGlobalMapper,
    GlobalResourceMapper<grptm.ClassWithMapperNamedMapperStrategy>?
        testGlobalResourceMapper,
    IriTermMapper<iptm.IriWithNamedMapper>? testIriMapper,
    LiteralTermMapper<lptm.LiteralWithNamedMapper>? testLiteralMapper,
    LiteralTermMapper<double>? testLiteralPriceMapper,
    LocalResourceMapper<Object>? testLocalMapper,
    LocalResourceMapper<lrptm.ClassWithMapperNamedMapperStrategy>?
        testLocalResourceMapper,
    IriTermMapper<grptm.ClassWithIriNamedMapperStrategy>? testMapper,
    IriTermMapper<
            (
              String id,
              String surname,
              int version,
            )>?
        testMapper3,
    GlobalResourceMapper<Object>? testNamedMapper}) {
  return initTestRdfMapper(
    baseUriProvider: baseUriProvider ?? (() => baseUri),
    iriMapper: iriMapper ?? const TestIriMapper(),
    mapEntryMapper: mapEntryMapper ?? const TestMapEntryMapper(),
    testCustomMapper: testCustomMapper ?? const TestCustomMapper(),
    testGlobalMapper: testGlobalMapper ?? const TestGlobalMapper(),
    testGlobalResourceMapper:
        testGlobalResourceMapper ?? const NamedTestGlobalResourceMapper(),
    testIriMapper: testIriMapper ?? const NamedTestIriMapper(),
    testLiteralMapper: testLiteralMapper ?? const NamedTestLiteralMapper(),
    testLiteralPriceMapper:
        testLiteralPriceMapper ?? const TestLiteralPriceMapper(),
    testLocalMapper: testLocalMapper ?? const TestLocalMapper(),
    testLocalResourceMapper:
        testLocalResourceMapper ?? const NamedTestLocalResourceMapper(),
    testMapper: testMapper ?? const TestMapper(),
    testMapper3: testMapper3 ?? const TestMapper3PartsWithProperties(),
    testNamedMapper: testNamedMapper ?? const TestNamedMapper(),
  );
}
