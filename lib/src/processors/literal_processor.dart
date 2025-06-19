import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Processes class elements to extract @RdfLiteral information.
class LiteralProcessor {
  static LiteralInfo? processClass(
      ValidationContext context, ClassElement2 classElement) {
    final annotation = getAnnotation(classElement.metadata2, 'RdfLiteral');
    final className = classToCode(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfIriAnnotation =
        _createRdfLiteralAnnotation(context, annotation, classElement);
    if (rdfIriAnnotation == null) {
      return null; // No valid resource annotation found
    }
    final fields = extractFields(classElement);
    final constructors = extractConstructors(classElement, fields, null);

    return LiteralInfo(
      className: className,
      annotation: rdfIriAnnotation,
      constructors: constructors,
      fields: fields,
    );
  }

  static RdfLiteralInfo? _createRdfLiteralAnnotation(ValidationContext context,
      DartObject? annotation, ClassElement2 classElement) {
    try {
      if (annotation == null) {
        return null;
      }

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<LiteralTermMapper>(annotation);
      final datatype = getIriTermInfo(getField(annotation, 'datatype'));
      final toLiteralTermMethod =
          getField(annotation, 'toLiteralTermMethod')?.toStringValue();

      final fromLiteralTermMethod =
          getField(annotation, 'fromLiteralTermMethod')?.toStringValue();

      // Create and return the RdfGlobalResource instance
      return RdfLiteralInfo(
        registerGlobally: registerGlobally,
        mapper: mapper,
        toLiteralTermMethod: toLiteralTermMethod,
        fromLiteralTermMethod: fromLiteralTermMethod,
        datatype: datatype,
      );
    } catch (e) {
      print('Error creating RdfGlobalResource: $e');
      rethrow;
    }
  }
}
