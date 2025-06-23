// Core IRI mapping functionality for RDF mapping

/// Interface for elements that have a name and metadata
abstract class NamedElement {
  String? get name;
  dynamic get metadata;
  dynamic get library;
}

/// Interface for type information
abstract class TypeInfo {
  String get name;
  String getDisplayName({bool withNullability = false});
  String getDisplayString({bool withNullability = false});
}

/// Interface for annotation values
abstract class AnnotationValue {
  dynamic getField(String name);
  String? toStringValue();
  bool? toBoolValue();
  bool get isNull;
  TypeInfo? get type;
}

/// Interface for library elements
abstract class LibraryInfo {
  String get identifier;
  List<dynamic> get metadata;
}

/// Maps between Dart objects and RDF IRIs.
@Deprecated('Unused?')
class IriMapper {
  /// Generates an IRI for the given [element] based on its type and annotations.
  ///
  /// Returns the generated IRI as a string, or `null` if no IRI could be generated.

  static String? generateIri(dynamic element, [Map<String, dynamic>? context]) {
    if (element is! NamedElement) return null;

    // First, check for @IriTerm or @IriTemplate annotations
    final iri = _getIriFromAnnotation(element);
    if (iri != null) {
      return iri;
    }

    // If no explicit IRI is provided, generate a default IRI based on the element's type and name
    return _generateDefaultIri(element, context);
  }

  /// Extracts an IRI from the element's annotations if present.
  static String? _getIriFromAnnotation(dynamic element) {
    if (element is! NamedElement) return null;

    // Check for @IriTerm annotation
    final iriTerm = _getAnnotationValue(element, 'IriTerm', 'iri');
    if (iriTerm != null) {
      return iriTerm.toString();
    }

    // Check for @IriTemplate annotation
    final iriTemplate = _getAnnotationValue(element, 'IriTemplate', 'template');
    if (iriTemplate != null) {
      // TODO: Implement template variable substitution
      return iriTemplate.toString();
    }

    return null;
  }

  /// Generates a default IRI based on the element's type and name.
  static String? _generateDefaultIri(dynamic element,
      [Map<String, dynamic>? context]) {
    if (element is! NamedElement) return null;

    final elementName = element.name;
    if (elementName == null || elementName.isEmpty) {
      return null;
    }

    // Get the package and library information
    final library = element.library;
    if (library == null) {
      return null;
    }

    String packageName = 'example';
    if (library is LibraryInfo) {
      final libraryName =
          library.identifier.replaceAll('package:', '').replaceAll('/', '.');
      packageName = libraryName.split('.').first;
    }

    // Generate a namespaced IRI
    final typeName = element.library != null ? element.name : '';
    final name = elementName.isNotEmpty ? elementName : '';

    // Create a basic IRI using package name and element details
    final typePart = typeName?.isNotEmpty == true ? '$typeName/' : '';
    final namePart = name.isNotEmpty ? name : '';
    return 'https://example.org/ns/$packageName/$typePart$namePart';
  }

  /// Helper method to get a value from an annotation on an element.
  static dynamic _getAnnotationValue(
      dynamic element, String annotationName, String fieldName) {
    if (element is! NamedElement) return null;

    final metadata = element.metadata;
    if (metadata is! List) return null;

    for (final annotation in metadata) {
      dynamic value;
      if (annotation is AnnotationValue) {
        value = annotation;
      } else if (annotation.toString().contains('MockElementAnnotation')) {
        // Handle mock annotation
        value = (annotation as dynamic).computeConstantValue();
      }

      if (value is AnnotationValue) {
        if (value.type?.name == annotationName) {
          final field = value.getField(fieldName);
          if (field != null && !(field.isNull ?? true)) {
            return field.toStringValue();
          }
        }
      }
    }
    return null;
  }

  /// Converts a Dart type to an XSD datatype IRI.
  static String? dartTypeToXsdType(dynamic type) {
    if (type is! TypeInfo) return null;

    final typeName = type.getDisplayString(withNullability: false);

    switch (typeName) {
      case 'String':
        return 'http://www.w3.org/2001/XMLSchema#string';
      case 'int':
      case 'double':
      case 'num':
        return 'http://www.w3.org/2001/XMLSchema#decimal';
      case 'bool':
        return 'http://www.w3.org/2001/XMLSchema#boolean';
      case 'DateTime':
        return 'http://www.w3.org/2001/XMLSchema#dateTime';
      default:
        return null;
    }
  }

  /// Gets the base IRI for a given library or package.
  static String? getBaseIri(dynamic library) {
    if (library is! LibraryInfo) return null;

    // First, check for package-level annotations
    for (final annotation in library.metadata) {
      dynamic value;
      if (annotation is AnnotationValue) {
        value = annotation;
      } else if (annotation.toString().contains('MockElementAnnotation')) {
        // Handle mock annotation
        value = (annotation as dynamic).computeConstantValue();
      }

      if (value is AnnotationValue && value.type?.name == 'BaseIri') {
        final iri = value.getField('iri')?.toStringValue();
        if (iri != null) {
          return iri;
        }
      }
    }

    // Fall back to package name based IRI
    final packageName =
        library.identifier.replaceAll('package:', '').split('/').first;
    if (packageName.isNotEmpty) {
      return 'https://example.org/ns/$packageName/';
    }

    return null;
  }
}
