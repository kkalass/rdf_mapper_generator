import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';

import 'code.dart';

const importRdfMapper = 'package:rdf_mapper/rdf_mapper.dart';

const importRdfCore = 'package:rdf_core/rdf_core.dart';
const importRdfVocab = 'package:rdf_vocabularies/rdf.dart';
const importXsd = 'package:rdf_vocabularies/xsd.dart';
const importSchema = 'package:rdf_vocabularies/schema.dart';

List<Map<String, dynamic>> toMustacheList<T>(List<T> values) {
  return List.generate(values.length, (i) {
    return {'value': values[i], 'last': i == values.length - 1};
  });
}

final stringType = Code.coreType('String');

Code typeToCode(DartType type, {bool enforceNonNull = false}) {
  var typeName = type.getDisplayString();
  if (enforceNonNull && typeName.endsWith('?')) {
    typeName = typeName.substring(0, typeName.length - 1);
  }
  final importUri = _getImportUriForType(type.element3);
  return Code.type(typeName, importUri: importUri);
}

Code enumToCode(EnumElement2 type) {
  final typeName = type.name3!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

Code classToCode(ClassElement2 type) {
  final typeName = type.name3!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

/// Converts a DartObject to a Code instance with proper import tracking
///
/// This function analyzes a compile-time constant value and generates the
/// corresponding Dart code along with any necessary import dependencies.
Code toCode(DartObject? value) {
  if (value == null || value.isNull) {
    return Code.value('null');
  }

  // Handle primitive types (no imports needed)
  if (value.type?.isDartCoreBool == true) {
    return Code.value(value.toBoolValue().toString());
  }
  if (value.type?.isDartCoreInt == true) {
    return Code.value(value.toIntValue().toString());
  }
  if (value.type?.isDartCoreDouble == true) {
    return Code.value(value.toDoubleValue().toString());
  }
  if (value.type?.isDartCoreString == true) {
    final str = value.toStringValue() ?? '';
    // Escape single quotes and wrap in single quotes
    return Code.value("'${str.replaceAll("'", "\\'")}'");
  }

  // Handle enums - these need import tracking
  if (value.type?.isDartCoreEnum == true) {
    final enumValue = value.getField('_name')?.toStringValue();
    final enumType = value.type!.getDisplayString();
    if (enumValue != null) {
      final importUri = _getImportUriForType(value.type!.element3);
      return Code.type('$enumType.$enumValue', importUri: importUri);
    }
  }

  // Handle lists
  if (value.type?.isDartCoreList == true) {
    final items = value.toListValue() ?? [];
    final itemCodes = items.map((item) => toCode(item)).toList();
    final combinedCode = Code.combine(itemCodes, separator: ', ');
    return Code.combine([Code.value('['), combinedCode, Code.value(']')]);
  }

  // Handle maps
  if (value.type?.isDartCoreMap == true) {
    final map = value.toMapValue() ?? {};
    final entryCodes = map.entries.map((entry) {
      final keyCode = toCode(entry.key);
      final valueCode = toCode(entry.value);
      return Code.combine([keyCode, Code.value(': '), valueCode]);
    }).toList();
    final combinedEntries = Code.combine(entryCodes, separator: ', ');
    return Code.combine([Code.value('{'), combinedEntries, Code.value('}')]);
  }

  if (value.variable2 != null) {
    // Handle variables (e.g., const variables)
    final variable = value.variable2!;
    final variableName = variable.name3;
    final enclosingElement = variable.enclosingElement2;
    if (enclosingElement is ClassElement2 &&
        variableName != null &&
        variable.isStatic) {
      return Code.combine(
          [classToCode(enclosingElement), Code.literal('.$variableName')]);
    }
  }

  // Handle objects with const constructors (like custom mappers)
  var typeElement = value.type?.element3;
  if (typeElement is ClassElement2) {
    for (final constructor in typeElement.constructors2) {
      final fields = constructor.formalParameters;
      if (constructor.isConst) {
        final constructorName = constructor.displayName;
        final positionalArgCodes = <Code>[];
        final namedArgCodes = <Code>[];

        // Separate positional and named parameters
        for (final field in fields) {
          final fieldValue = value.getField(field.name3!);
          if (fieldValue != null) {
            final fieldCode = toCode(fieldValue);

            if (field.isNamed) {
              // Named parameter: paramName: value
              namedArgCodes.add(
                  Code.combine([Code.value('${field.name3!}: '), fieldCode]));
            } else {
              // Positional parameter: just the value
              positionalArgCodes.add(fieldCode);
            }
          }
        }

        // Combine positional and named arguments
        final allArgCodes = <Code>[];
        allArgCodes.addAll(positionalArgCodes);
        allArgCodes.addAll(namedArgCodes);

        final argsCode = Code.combine(allArgCodes, separator: ', ');
        final importUri = _getImportUriForType(typeElement);

        return Code.combine([
          Code.constructor('const $constructorName(', importUri: importUri),
          argsCode,
          Code.value(')')
        ]);
      }
    }
  }

  // Fallback to string representation if type is not recognized
  return Code.value(value.toStringValue() ?? '');
}

/// Determines the import URI for a given type element
String? _getImportUriForType(Element2? element) {
  if (element == null) return null;

  final source = element.library2?.identifier;
  final sourceUri = element.library2?.uri;
  if (source == null || sourceUri == null) return null;

  return source.toString();
}

Code codeGeneric1(Code mapperInterface, Code className) => Code.combine([
      mapperInterface,
      Code.literal('<'),
      className,
      Code.literal('>'),
    ]);

Code codeGeneric2(Code type, Code p1, Code p2) => Code.combine(
    [type, Code.literal('<'), p1, Code.literal(', '), p2, Code.literal('>')]);

Code createConstructorCall(
    Code className, List<ConstructorParameterData> constructorParameters,
    {bool constContext = false}) {
  return Code.combine([
    if (constContext) Code.literal(' const '),
    className,
    Code.literal('('),
    Code.combine(
        constructorParameters
            .map((p) => Code.combine([
                  Code.literal(p.parameterName),
                  Code.literal(': '),
                  Code.literal(p.parameterName)
                ]))
            .toList(),
        separator: ', '),
    Code.literal(')')
  ]);
}
