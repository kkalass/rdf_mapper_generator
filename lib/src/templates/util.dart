import 'package:analyzer/dart/constant/value.dart';

List<Map<String, dynamic>> toMustacheList<T>(List<T> values) {
  return List.generate(values.length, (i) {
    return {'value': values[i], 'last': i == values.length - 1};
  });
}

String toCode(DartObject? value) {
  // FIXME: proper Dart code generation that creates the actual code for the value
  return value?.toStringValue() ?? '';
}
