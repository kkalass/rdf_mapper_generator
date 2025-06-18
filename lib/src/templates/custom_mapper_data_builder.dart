import 'package:rdf_mapper_generator/src/processors/models/resource_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

class CustomMapperDataBuilder {
  static CustomMapperTemplateData build(ValidationContext context,
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

    var customMapperName = mapper.name;
    var customMapperType =
        mapper.type == null ? null : typeToCode(mapper.type!.toTypeValue()!);
    var customMapperInstance =
        mapper.instance == null ? null : toCode(mapper.instance);
    if (customMapperName == null &&
        customMapperType == null &&
        customMapperInstance == null) {
      context.addError(
        'Custom mapper must have either a name or a type defined in the annotation.',
      );
    }
    return CustomMapperTemplateData(
      className: className,
      mapperInterfaceType: mapperInterfaceType,
      customMapperName: customMapperName,
      customMapperType: customMapperType,
      customMapperInstance: customMapperInstance,
      registerGlobally: annotation.registerGlobally,
    );
  }

  static Code mapperInterfaceNameFor(
      BaseMappingAnnotationInfo<dynamic> annotation) {
    return Code.type(
        switch (annotation) {
          RdfGlobalResourceInfo() => 'GlobalResourceMapper',
          RdfLocalResourceInfo() => 'LocalResourceMapper',
        },
        importUri: importRdfMapper);
  }
}
