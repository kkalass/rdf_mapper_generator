import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:rdf_vocabularies_core/solid.dart';
import 'package:rdf_vocabularies_core/pim.dart';

final turtleDocument = '''
@prefix : <#>.
@prefix foaf: <http://xmlns.com/foaf/0.1/>.
@prefix schema: <http://schema.org/>.
@prefix solid: <http://www.w3.org/ns/solid/terms#>.
@prefix space: <http://www.w3.org/ns/pim/space#>.
@prefix pro: <./>.
@prefix kk: </>.

pro:card a foaf:PersonalProfileDocument; foaf:maker :me; foaf:primaryTopic :me.

:me
    a schema:Person, foaf:Person;
    space:preferencesFile </settings/prefs.ttl>;
    space:storage kk:;
    solid:account kk:;
    solid:oidcIssuer <https://datapod.igrant.io>;
    solid:privateTypeIndex </settings/privateTypeIndex.ttl>;
    solid:publicTypeIndex </settings/publicTypeIndex.ttl>;
    foaf:name "Klas Kala\u00df".
''';

@RdfGlobalResource(FoafDocument.classIri, IriStrategy(),
    registerGlobally: false)
class Document<T> {
  @RdfIriPart()
  @RdfProvides()
  final String documentIri;

  @RdfProperty(FoafDocument.primaryTopic,
      contextual: ContextualMapping.named("primaryTopic"))
  final T primaryTopic;

  @RdfProperty(FoafDocument.maker)
  final Uri maker;

// FIXME: this should have some flag like 'global' to grab all unmapped triples
  @RdfUnmappedTriples()
  final RdfGraph unmapped;

  Document(
      {required this.documentIri,
      required this.maker,
      required this.primaryTopic,
      required this.unmapped});
}

@RdfGlobalResource(FoafPerson.classIri, IriStrategy("{+documentIri}#me"),
    registerGlobally: false)
class Person {
  @RdfProperty(FoafPerson.name)
  String name;

  @RdfProperty(FoafPerson.pimPreferencesFile)
  Uri preferencesFile;

  @RdfProperty(Pim.storage)
  Uri storage;

  @RdfProperty(Solid.account)
  Uri account;

  @RdfProperty(Solid.oidcIssuer)
  Uri oidcIssuer;

  @RdfProperty(Solid.privateTypeIndex)
  Uri privateTypeIndex;

  @RdfProperty(Solid.publicTypeIndex)
  Uri publicTypeIndex;

  @RdfUnmappedTriples()
  RdfGraph other;

  Person(
      {required this.name,
      required this.preferencesFile,
      required this.storage,
      required this.account,
      required this.oidcIssuer,
      required this.privateTypeIndex,
      required this.publicTypeIndex,
      required this.other});
}
