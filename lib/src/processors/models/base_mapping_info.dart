import 'package:analyzer/dart/element/element2.dart';

class MapperRefInfo<M> {
  final String? name;

  final FormalParameterElement? type;

  final FormalParameterElement? instance;

  const MapperRefInfo(
      {required this.name, required this.type, required this.instance});
}

class BaseMappingInfo<M> {
  final MapperRefInfo<M>? mapper;
  const BaseMappingInfo({required this.mapper});
}
