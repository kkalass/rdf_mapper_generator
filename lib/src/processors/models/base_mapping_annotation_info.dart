import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';

class BaseMappingAnnotationInfo<T> extends BaseMappingInfo<T> {
  final bool registerGlobally;
  const BaseMappingAnnotationInfo({
    this.registerGlobally = true,
    super.mapper,
  });
}
