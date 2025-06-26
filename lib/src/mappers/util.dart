import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';

EnumValueModel toEnumValueModel(EnumValueInfo e) {
  return EnumValueModel(
    constantName: e.constantName,
    serializedValue: e.serializedValue,
  );
}
