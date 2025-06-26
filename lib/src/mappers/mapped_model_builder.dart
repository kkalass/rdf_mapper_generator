import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/processors/models/property_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';

import '../processors/models/mapper_info.dart';
import 'mapper_model.dart';

/// Builds mapper models from info objects (conversion from Info layer to Model layer)
///
/// FIXME: this contains a lot of the original template data layer,  we should probably clean this up.
class MappedClassModelBuilder {
  static MappedClassModel buildMappedClassModel(
      Code mappedClass,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields,
      bool Function(ParameterData) rdfFilter) {
    // Build constructor parameters
    final constructorParameters = _buildConstructorParameters(
        mappedClass, constructors, fields, mapperImportUri);

    // Collect non-constructor fields that are RDF value or language tag fields
    final allNonConstructorFields = _buildNonConstructorFields(
        mappedClass, constructorParameters, fields, null, mapperImportUri);
    final nonConstructorRdfFields =
        allNonConstructorFields.where(rdfFilter).toList();

    // Combine constructor and non-constructor RDF fields for validation
    final constructorRdfFields =
        constructorParameters.where(rdfFilter).toList();

    final properties = _buildPropertyData(mappedClass, fields, mapperImportUri);

    return MappedClassModel(
        className: mappedClass,
        constructorParameters: constructorParameters,
        nonConstructorRdfFields: nonConstructorRdfFields,
        constructorRdfFields: constructorRdfFields,
        properties: properties);
  }

  /// Builds constructor parameter data for the template.
  static Iterable<ParameterData> _buildNonConstructorFields(
      Code className,
      List<ParameterData> constructorParameters,
      List<FieldInfo> fields,
      IriData? iriStrategy,
      String mapperImportUri) {
    final constructorParameterNames =
        constructorParameters.map((p) => p.name).toSet();
    final iriPartNameByPropertyName = {
      for (var pv in (iriStrategy?.iriMapperParts ?? <IriPartData>[]))
        pv.dartPropertyName: pv.name
    };
    final provides = _collectProvidesByVariableNames(fields);
    return fields
        .where((f) => !constructorParameterNames.contains(f.name))
        .map((field) {
      final predicateCode = field.propertyInfo?.annotation.predicate.code;
      final defaultValue = field.propertyInfo?.annotation.defaultValue;
      final iriPartName = iriPartNameByPropertyName[field.name];
      final isIriPart = iriPartName != null;
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, field.name, field.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameAsCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);

      final (readerMethod, _) =
          _getReaderAndSerializerMethods(field.propertyInfo, field.isRequired);

      return ParameterData(
        name: field.name,
        dartType: field.type,
        isRequired: field.isRequired,
        // For RDF properties, check if the field is nullable. If not an RDF property, assume non-nullable
        isFieldNullable: field.propertyInfo != null
            ? !field.propertyInfo!.isRequired
            : false,
        isIriPart: isIriPart,
        isRdfProperty: predicateCode != null,
        isNamed: false,
        iriPartName: iriPartName,
        predicate: predicateCode,
        defaultValue: toCode(defaultValue),
        hasDefaultValue: defaultValue != null,
        isRdfLanguageTag: field.isRdfLanguageTag,
        isRdfValue: field.isRdfValue,
        mapperFieldName: mapperFieldName,
        mapperParameterSerializer: mapperParameterSerializer,
        mapperParameterDeserializer: mapperParameterDeserializer,
        mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameAsCode,
        mapperDeserializerCode: mapperDeserializerCode ?? mapperFieldNameAsCode,
        readerMethod: readerMethod,
        isMap: field.propertyInfo?.collectionInfo.isMap ?? false,
        isList: field.propertyInfo?.collectionInfo.isList ?? false,
        isSet: field.propertyInfo?.collectionInfo.isSet ?? false,
        isCollection: field.propertyInfo?.collectionInfo.isCollection ?? false,
      );
    });
  }

  static List<ParameterData> _buildConstructorParameters(
      Code className,
      List<ConstructorInfo> constructors,
      List<FieldInfo> fields,
      String mapperImportUri) {
    final provides = _collectProvidesByVariableNames(fields);
    final parameters = <ParameterData>[];
    if (constructors.isEmpty) {
      return parameters; // No constructors, return empty list
    }
    // Find the default constructor or use the first one if no default exists
    final defaultConstructor = constructors.firstWhere(
      (c) => c.isDefaultConstructor,
      orElse: () => constructors.first,
    );

    // Process each parameter in the constructor
    for (final param in defaultConstructor.parameters) {
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, param.name, param.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameAsCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);
      // Determine reader method based on collection information
      final isFieldNullable = param.propertyInfo != null
          ? !param.propertyInfo!.isRequired
          : false; // Assume non-nullable if not an RDF property

      final defaultValue = param.propertyInfo?.annotation.defaultValue;
      final (readerMethod, _) = _getReaderAndSerializerMethods(
          param.propertyInfo, !isFieldNullable && defaultValue == null);

      final defaultValueCode = toCode(defaultValue);

      parameters.add(
        ParameterData(
          name: param.name,
          dartType: param.type,
          isRequired: param.isRequired,
          // For RDF properties, check if the field is nullable. If not an RDF property, assume non-nullable
          isFieldNullable: isFieldNullable,
          isIriPart: param.isIriPart,
          isRdfProperty: param.propertyInfo != null,
          isNamed: param.isNamed,
          iriPartName: param.iriPartName,
          predicate: param.propertyInfo?.annotation.predicate.code,
          defaultValue: defaultValueCode,
          hasDefaultValue: defaultValue != null,
          isRdfLanguageTag: param.isRdfLanguageTag,
          isRdfValue: param.isRdfValue,
          mapperFieldName: mapperFieldName,
          mapperParameterSerializer: mapperParameterSerializer,
          mapperParameterDeserializer: mapperParameterDeserializer,
          mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameAsCode,
          mapperDeserializerCode:
              mapperDeserializerCode ?? mapperFieldNameAsCode,
          readerMethod: readerMethod,
          isMap: param.propertyInfo?.collectionInfo.isMap ?? false,
          isList: param.propertyInfo?.collectionInfo.isList ?? false,
          isSet: param.propertyInfo?.collectionInfo.isSet ?? false,
          isCollection:
              param.propertyInfo?.collectionInfo.isCollection ?? false,
        ),
      );
    }

    return parameters;
  }

  static List<PropertyData> _buildPropertyData(
      Code className, List<FieldInfo> fields, String mapperImportUri) {
    final provides = _collectProvidesByVariableNames(fields);
    return fields.where((p) => p.propertyInfo != null).map((p) {
      final (
        mapperFieldName,
        mapperSerializerCode,
        mapperDeserializerCode,
        mapperParameterSerializer,
        mapperParameterDeserializer
      ) = _extractPropertyMapperInfos(
          className, p.name, p.propertyInfo, provides, mapperImportUri);
      final mapperFieldNameCode =
          mapperFieldName == null ? null : Code.literal(mapperFieldName);

      // Determine collection information and methods
      final collectionInfo = p.propertyInfo!.collectionInfo;
      final (readerMethod, serializerMethod) =
          _getReaderAndSerializerMethods(p.propertyInfo, p.isRequired);

      return PropertyData(
        isRdfProperty: p.propertyInfo != null,
        isRequired: p.isRequired,
        isFieldNullable: !p.isRequired,
        include: p.propertyInfo!.annotation.include,
        predicate: p.propertyInfo!.annotation.predicate.code,
        propertyName: p.propertyInfo!.name,
        defaultValue: toCode(p.propertyInfo!.annotation.defaultValue),
        hasDefaultValue: p.propertyInfo!.annotation.defaultValue != null,
        includeDefaultsInSerialization:
            p.propertyInfo!.annotation.includeDefaultsInSerialization,
        mapperFieldName: mapperFieldName,
        mapperParameterSerializer: mapperParameterSerializer,
        mapperParameterDeserializer: mapperParameterDeserializer,
        mapperSerializerCode: mapperSerializerCode ?? mapperFieldNameCode,
        mapperDeserializerCode: mapperDeserializerCode ?? mapperFieldNameCode,
        isCollection: collectionInfo.isCollection,
        isMap: collectionInfo.isMap,
        readerMethod: readerMethod,
        serializerMethod: serializerMethod,
        dartType: p.type,
        isList: collectionInfo.isList,
        isSet: collectionInfo.isSet,
      );
    }).toList();
  }

  static String _buildMapperFieldName(String fieldName) =>
      '_' + fieldName + 'Mapper';

  static Map<String, ProvidesInfo> _collectProvidesByVariableNames(
          List<FieldInfo> fields) =>
      {
        for (final p in fields
            .expand((f) => f.provides == null ? const [] : [f.provides!]))
          p.name: p
      };

  static Code _buildPropertyMapperName(
      Code className, String fieldName, String mapperImportUri) {
    return Code.type(
        '${className.codeWithoutAlias}${_capitalizeFirstLetter(fieldName)}Mapper',
        importUri: mapperImportUri);
  }

  static String _capitalizeFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  static const (
    String? mapperFieldName,
    Code? mapperSerializerCode,
    Code? mapperDeserializerCode,
    String? mapperParameterSerializer,
    String? mapperParameterDeserializer
  ) _noMapperInfos = (
    null,
    null,
    null,
    null,
    null,
  );

  static (
    String? mapperFieldName,
    Code? mapperSerializerCode,
    Code? mapperDeserializerCode,
    String? mapperParameterSerializer,
    String? mapperParameterDeserializer
  ) _extractPropertyMapperInfos(
      Code className,
      String fieldName,
      PropertyInfo? propertyInfo,
      Map<String, ProvidesInfo> providesByVariableNames,
      String mapperImportUri) {
    if (propertyInfo == null) {
      return _noMapperInfos;
    }

    final collectionInfo = propertyInfo.collectionInfo;

    final iri = propertyInfo.annotation.iri;
    if (iri != null) {
      final template = iri.template;
      final iriMapperFieldName = _buildMapperFieldName(fieldName);
      final generatedMapperName =
          _buildPropertyMapperName(className, fieldName, mapperImportUri);
      return (
        iriMapperFieldName,
        template == null
            ? null
            : _buildIriMapperSerializerCode(generatedMapperName, template,
                iriMapperFieldName, providesByVariableNames),
        template == null
            ? null
            : _buildIriMapperDeserializerCode(generatedMapperName, template,
                iriMapperFieldName, providesByVariableNames),
        'iriTermSerializer',
        'iriTermDeserializer'
      );
    }
    final literal = propertyInfo.annotation.literal;
    if (literal != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'literalTermSerializer',
        'literalTermDeserializer'
      );
    }
    final globalResource = propertyInfo.annotation.globalResource;
    if (globalResource != null && globalResource.mapper != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'resourceSerializer',
        'globalResourceDeserializer'
      );
    }
    final localResource = propertyInfo.annotation.localResource;
    if (localResource != null && localResource.mapper != null) {
      return (
        _buildMapperFieldName(fieldName),
        null,
        null,
        'resourceSerializer',
        'localResourceDeserializer'
      );
    }

    // For collections without explicit mapping, we need to determine the serialization method
    if (collectionInfo.isCollection) {
      return (
        null, // No custom mapper field needed
        null,
        null,
        collectionInfo.isMap ? 'resourceSerializer' : 'valueIterable',
        collectionInfo.isMap
            ? 'globalResourceDeserializer'
            : 'globalResourceDeserializer'
      );
    }

    return _noMapperInfos;
  }

  static _buildIriMapperSerializerCode(
      Code generatedMapperConstructorName,
      IriTemplateInfo iri,
      String iriMapperFieldName,
      Map<String, ProvidesInfo> providesByVariableNames) {
    if (iri.contextVariables.isEmpty) {
      // No context variables at all, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    final hasProvides =
        iri.contextVariables.any((v) => providesByVariableNames.containsKey(v));
    if (!hasProvides) {
      // All context variables will be injected, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    // we will need to build our own initialization code
    return Code.combine([
      generatedMapperConstructorName,
      Code.literal('('),
      ...iri.contextVariables.map((v) {
        final provides = providesByVariableNames[v];
        if (provides == null) {
          // context variable is not provided, so it will be injected as a field
          return Code.literal('${v}Provider: _${v}Provider, ');
        }
        return Code.literal(
            '${v}Provider: () => resource.${provides.dartPropertyName}, ');
      }),
      Code.literal(')')
    ]);
  }

  static (Code readerMethod, Code serializerMethod)
      _getReaderAndSerializerMethods(
          PropertyInfo? propertyInfo, bool isRequired) {
    final collection = propertyInfo?.annotation.collection;
    final collectionInfo = propertyInfo?.collectionInfo;
    // Determine reader and serializer methods based on collection type
    final isCollection = collectionInfo?.isCollection ?? false;
    final isMap = collectionInfo?.isMap ?? false;
    final isIterable = collectionInfo?.isIterable ?? false;

    if (isCollection && collection != RdfCollectionType.none) {
      if (isMap) {
        return const (Code.literal('getMap'), Code.literal('addMap'));
      }
      if (isIterable) {
        final elementType = collectionInfo!.elementTypeCode!;
        return (
          codeGeneric1(Code.literal('getValues'), elementType),
          codeGeneric1(Code.literal('addValues'), elementType),
        );
      }
    }
    if (isRequired) {
      return const (Code.literal('require'), Code.literal('addValue'));
    }
    return const (Code.literal('optional'), Code.literal('addValue'));
  }

  static _buildIriMapperDeserializerCode(
      Code generatedMapperConstructorName,
      IriTemplateInfo iri,
      String iriMapperFieldName,
      Map<String, ProvidesInfo> providesByVariableNames) {
    if (iri.contextVariables.isEmpty) {
      // No context variables at all, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    final hasProvides =
        iri.contextVariables.any((v) => providesByVariableNames.containsKey(v));
    if (!hasProvides) {
      // All context variables will be injected, the mapper will be initialized as a field.
      return Code.literal(iriMapperFieldName);
    }
    // we will need to build our own initialization code
    return Code.combine([
      generatedMapperConstructorName,
      Code.literal('('),
      ...iri.contextVariables.map((v) {
        final provides = providesByVariableNames[v];
        if (provides == null) {
          // context variable is not provided, so it will be injected as a field
          return Code.literal('${v}Provider: _${v}Provider, ');
        }
        return Code.literal(
            "${v}Provider: () => throw Exception('Must not call provider for deserialization'), ");
      }),
      Code.literal(')')
    ]);
  }
}
