import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Contains information about a field annotated with `@RdfProperty`
class PropertyInfo {
  /// The name of the field
  final String name;

  /// The type of the field as a string
  final String type;

  // FIXME convert to RdfPropertyInfo
  /// The complete RdfProperty annotation instance
  final RdfProperty annotation;

  /// Whether this is a required field
  final bool isRequired;

  /// Whether this is a final field
  final bool isFinal;

  /// Whether this is a late-initialized field
  final bool isLate;

  /// Whether this is a static field
  final bool isStatic;

  /// Whether this is a synthetic field
  final bool isSynthetic;

  /// The IRI of the RDF property (computed from the annotation)
  String get propertyIri => annotation.predicate.iri;

  /// The IRI mapping strategy for this property (if any)
  String? get iriMapping => annotation.iri?.template;

  const PropertyInfo({
    required this.name,
    required this.type,
    required this.annotation,
    required this.isRequired,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
  });

  @override
  String toString() {
    return 'PropertyInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  propertyIri: $propertyIri,\n'
        '  isRequired: $isRequired,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic,\n'
        '  iriMapping: $iriMapping\n'
        '}';
  }
}
