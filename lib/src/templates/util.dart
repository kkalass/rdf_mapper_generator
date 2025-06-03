import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';

List<Map<String, dynamic>> toMustacheList<T>(List<T> values) {
  return List.generate(values.length, (i) {
    return {'value': values[i], 'last': i == values.length - 1};
  });
}

// FIXME: create many test cases for this function
String toCode(DartObject? value) {
  if (value == null || value.isNull) {
    return 'null';
  }

  // Handle primitive types
  if (value.type?.isDartCoreBool == true) {
    return value.toBoolValue().toString();
  }
  if (value.type?.isDartCoreInt == true) {
    return value.toIntValue().toString();
  }
  if (value.type?.isDartCoreDouble == true) {
    return value.toDoubleValue().toString();
  }
  if (value.type?.isDartCoreString == true) {
    final str = value.toStringValue() ?? '';
    // Escape single quotes and wrap in single quotes
    return "'${str.replaceAll("'", "\\'")}'";
  }

  // Handle enums
  if (value.type?.isDartCoreEnum == true) {
    final enumValue = value.getField('_name')?.toStringValue();
    final enumType = value.type!.getDisplayString();
    if (enumValue != null) {
      return '$enumType.$enumValue';
    }
  }

  // Handle const constructors (like IriTerm, etc.)
  final type = value.type?.getDisplayString();
  if (type == 'IriTerm') {
    final iri = value.getField('iri')?.toStringValue();
    if (iri != null) {
      return "IriTerm('${_escapeString(iri)}')";
    }
  }

  // Handle lists
  if (value.type?.isDartCoreList == true) {
    final items = value.toListValue() ?? [];
    final itemCodes = items.map((item) => toCode(item)).join(', ');
    return '[$itemCodes]';
  }

  // Handle maps
  if (value.type?.isDartCoreMap == true) {
    final map = value.toMapValue() ?? {};
    final entries = map.entries.map((entry) {
      return '${toCode(entry.key)}: ${toCode(entry.value)}';
    }).join(', ');
    return '{$entries}';
  }

  // Handle objects with const constructors (like TestMapper)
  var typeElement = value.type?.element3;
  if (typeElement is ClassElement2) {
    for (final constructor in typeElement.constructors2) {
      final fields = constructor.formalParameters;
      if (constructor.isConst) {
        final constructorName = constructor.displayName;
        final namedArgs = <String, String>{};

// FIXME: handle positional arguments
        for (final field in fields) {
          final fieldValue = value.getField(field.name3!);
          if (fieldValue != null) {
            namedArgs[field.name3!] = toCode(fieldValue);
          }
        }

        final args =
            namedArgs.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        return 'const $constructorName($args)';
      }
    }
  }

  // Fallback to string representation if type is not recognized
  return value.toStringValue() ?? '';
}

String _escapeString(String input) {
  return input.replaceAll("'", "\\'");
}
