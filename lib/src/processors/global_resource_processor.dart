import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart'; // For Resolver
// import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart'; // Removing as type check is by string

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
  final ClassElement2 classElement; // Updated to ClassElement2
  final Resolver resolver;

  GlobalResourceProcessor(this.classElement, this.resolver);

  ProcessedClassInfo? process() {
    if (!_hasRdfGlobalResourceAnnotation(classElement)) {
      return null;
    }

    final String className = classElement.displayName; // Changed to .displayName
    final List<Map<String, dynamic>> constructorsInfo = [];
    final List<Map<String, String>> fieldsInfo = [];

    // Extract constructor details
    for (final constructorElement in classElement.constructors2.where((c) => !c.isFactory && c.isPublic)) {
      final List<Map<String, String>> parametersInfo = [];
      // Changing to .parameters2 for ConstructorElement2
      for (final parameterElement in constructorElement.parameters2) { 
        parametersInfo.add({
          'name': parameterElement.name, // Assuming .name is correct for ParameterElement2
          'type': parameterElement.type.getDisplayString(),
        });
      }
      constructorsInfo.add({
        'name': constructorElement.displayName.isEmpty ? '' : constructorElement.displayName, // Changed to .displayName
        'parameters': parametersInfo,
      });
    }

    // Extract field details
    for (final fieldElement in classElement.fields2.where((f) => !f.isStatic && f.isPublic)) {
      fieldsInfo.add({
        'name': fieldElement.displayName, // Changed to .displayName
        'type': fieldElement.type.getDisplayString(),
      });
    }

    return ProcessedClassInfo(
      className: className,
      constructors: constructorsInfo,
      fields: fieldsInfo,
    );
  }

  bool _hasRdfGlobalResourceAnnotation(ClassElement2 element) {
    // Changing to element.annotations for ClassElement2
    for (final annotationNode in element.annotations) { 
      final annotationValue = annotationNode.computeConstantValue();
      if (annotationValue != null && annotationValue.type?.getDisplayString() == 'RdfGlobalResource') {
        return true;
      }
    }
    return false;
  }
}
