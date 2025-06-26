import 'package:rdf_mapper_generator/src/templates/code.dart';

class TypeInfo {
  final Code name;

  TypeInfo({required this.name});

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
