import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

class ProcessedClassInfo {
  final String className;
  final List<Map<String, dynamic>> constructors; // e.g. [{'name': 'constructorName', 'parameters': [{'name': 'paramName', 'type': 'paramType'}]}]
  final List<Map<String, String>> fields; // e.g. [{'name': 'fieldName', 'type': 'fieldType'}]

  ProcessedClassInfo({
    required this.className,
    required this.constructors,
    required this.fields,
  });
}

class GlobalResourceProcessor {
  final ClassElement classElement;
  final Resolver resolver;

  GlobalResourceProcessor(this.classElement, this.resolver);

  ProcessedClassInfo? process() {
    if (!_hasRdfGlobalResourceAnnotation(classElement)) {
      return null;
    }

    final String className = classElement.name;
    final List<Map<String, dynamic>> constructorsInfo = [];
    final List<Map<String, String>> fieldsInfo = [];

    // Extract constructor details
    for (final constructorElement in classElement.constructors) {
      // We are interested in public, non-factory constructors
      if (!constructorElement.isFactory && constructorElement.isPublic) {
        final List<Map<String, String>> parametersInfo = [];
        for (final parameterElement in constructorElement.parameters) {
          parametersInfo.add({
            'name': parameterElement.name,
            'type': parameterElement.type.getDisplayString(withNullability: true),
          });
        }
        constructorsInfo.add({
          'name': constructorElement.name.isEmpty ? '' : constructorElement.name, // Default constructor has empty name
          'parameters': parametersInfo,
        });
      }
    }

    // Extract field details
    for (final fieldElement in classElement.fields) {
       // We are interested in public, non-static fields
      if (!fieldElement.isStatic && fieldElement.isPublic) {
        fieldsInfo.add({
          'name': fieldElement.name,
          'type': fieldElement.type.getDisplayString(withNullability: true),
        });
      }
    }

    return ProcessedClassInfo(
      className: className,
      constructors: constructorsInfo,
      fields: fieldsInfo,
    );
  }

  bool _hasRdfGlobalResourceAnnotation(ClassElement element) {
    for (final metadata in element.metadata) {
      final annotation = metadata.computeConstantValue();
      if (annotation != null && annotation.type?.displayName == 'RdfGlobalResource') {
        return true;
      }
    }
    return false;
  }
}
