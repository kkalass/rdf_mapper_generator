import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

EnumValueModel toEnumValueModel(EnumValueInfo e) {
  return EnumValueModel(
    constantName: e.constantName,
    serializedValue: e.serializedValue,
  );
}

/// Builds the mapper interface type, considering collection types
Code buildMapperInterfaceTypeForProperty(
    Code mapperInterface, CollectionInfo? collectionInfo, Code typeNonNull) {
  if (collectionInfo == null || !collectionInfo.isCollection) {
    return codeGeneric1(mapperInterface, typeNonNull);
  }

  // For collections, the mapper type should be for the element type
  if (collectionInfo.isMap &&
      collectionInfo.keyTypeCode != null &&
      collectionInfo.valueTypeCode != null) {
    // For maps, use MapEntry<K,V> as the element type
    final mapEntryType = codeGeneric2(Code.type('MapEntry'),
        collectionInfo.keyTypeCode!, collectionInfo.valueTypeCode!);
    return codeGeneric1(mapperInterface, mapEntryType);
  } else if (collectionInfo.elementTypeCode != null) {
    // For List/Set, use the element type
    return codeGeneric1(mapperInterface, collectionInfo.elementTypeCode!);
  }
  return codeGeneric1(mapperInterface, typeNonNull);
}
