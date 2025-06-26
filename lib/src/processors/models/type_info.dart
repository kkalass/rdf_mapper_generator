import 'package:rdf_mapper_generator/src/templates/code.dart';

class TypeInfo {
  final Code name;

// this will also receive constructor parameter information, so that we can
// generate the correct constructor call
  TypeInfo({required this.name});

  Code generateConstructorCall({bool constContext = false}) {
    return Code.combine(
        [if (constContext) Code.literal(' const '), name, Code.literal('()')]);
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! TypeInfo) {
      return false;
    }
    return name == other.name;
  }

  @override
  String toString() {
    return 'TypeInfo{name: $name}';
  }
}
