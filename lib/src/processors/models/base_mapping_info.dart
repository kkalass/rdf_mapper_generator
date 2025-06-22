import 'package:analyzer/dart/constant/value.dart';

class MapperRefInfo<M> {
  final String? name;

  final DartObject? type;

  final DartObject? instance;

  const MapperRefInfo(
      {required this.name, required this.type, required this.instance});

  @override
  int get hashCode => Object.hashAll([name, type, instance]);

  @override
  bool operator ==(Object other) {
    if (other is! MapperRefInfo<M>) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        instance == other.instance;
  }

  @override
  String toString() {
    return 'MapperRefInfo{'
        'name: $name, '
        'type: $type, '
        'instance: $instance}';
  }
}

class BaseMappingInfo<M> {
  final MapperRefInfo<M>? mapper;
  const BaseMappingInfo({required this.mapper});

  @override
  int get hashCode => Object.hashAll([mapper]);

  @override
  bool operator ==(Object other) {
    if (other is! BaseMappingInfo<M>) {
      return false;
    }
    return mapper == other.mapper;
  }

  @override
  String toString() {
    return 'BaseMappingInfo{mapper: $mapper}';
  }
}
