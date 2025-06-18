import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

class CustomMapperDataBuilder {
  static CustomMapperTemplateData build(
      Code className, BaseMappingAnnotationInfo annotation) {
    assert(annotation.mapper != null);
    final mapper = annotation.mapper!;
    final mapperInterfaceName = mapperInterfaceNameFor(annotation);

    final mapperInterfaceType = Code.combine([
      mapperInterfaceName,
      Code.literal('<'),
      className,
      Code.literal('>'),
    ]);
    // Build imports

    return CustomMapperTemplateData(
      imports: const [],
      className: className,
      mapperInterfaceType: mapperInterfaceType,
      customMapperName: mapper.name,
      customMapperType: mapper.type == null ? null : toCode(mapper.type),
      customMapperInstance: mapper.type == null ? null : toCode(mapper.type),
      registerGlobally: annotation.registerGlobally,
    );
  }

  static Code mapperInterfaceNameFor(
      BaseMappingAnnotationInfo<dynamic> annotation) {
    return Code.type(switch (annotation) {
      RdfGlobalResourceInfo() => 'GlobalResourceMapper',
      RdfLocalResourceInfo() => 'LocalResourceMapper',
    });
  }
}
