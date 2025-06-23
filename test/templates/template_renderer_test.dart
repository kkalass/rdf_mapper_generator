import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';

void main() {
  group('TemplateRenderer', () {
    late TemplateRenderer renderer;

    setUp(() {
      renderer = TemplateRenderer();
    });

    group('resolveCodeSnipplets', () {
      test('resolves simple Code instance', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final data = {
          'someField': 'value',
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['someField'], equals('value'));
        expect(result['codeField'], equals('bar.MyClass'));
        expect(result['aliasedImports'], hasLength(1));
        expect(
            result['aliasedImports'][0]['uri'], equals('package:foo/bar.dart'));
        expect(result['aliasedImports'][0]['alias'], equals('bar'));
        expect(result['aliasedImports'][0]['hasAlias'], isTrue);
      });
      test('resolves simple Code instance without alias if requested so', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final data = {
          'someField': 'value',
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data,
            defaultImports: ['package:foo/bar.dart']);

        expect(result['someField'], equals('value'));
        expect(result['codeField'], equals('MyClass'));
        expect(result['aliasedImports'], hasLength(0));
      });

      test('resolves nested Code instances', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:bar/b.dart');

        final data = {
          'nested': {
            'code1': code1.toMap(),
            'someList': [
              'string',
              code2.toMap(),
              123,
            ],
          },
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['nested']['code1'], equals('a.ClassA'));
        expect(result['nested']['someList'][0], equals('string'));
        expect(result['nested']['someList'][1], equals('b.ClassB'));
        expect(result['nested']['someList'][2], equals(123));
        expect(result['aliasedImports'], hasLength(2));
      });

      test('respects known imports without aliases', () {
        final code = Code.coreType('MyClass');
        final data = {
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['codeField'], equals('MyClass'));
        expect(result['aliasedImports'], hasLength(1));
        expect(result['aliasedImports'][0]['uri'], equals('dart:core'));
        expect(result['aliasedImports'][0]['alias'], equals(''));
        expect(result['aliasedImports'][0]['hasAlias'], isFalse);
      });

      test('handles alias conflicts with known imports', () {
        final code1 = Code.type('ClassA', importUri: 'package:a/foo.dart');
        final code2 = Code.type('ClassB', importUri: 'package:b/foo.dart');

        final data = {
          'code1': code1.toMap(),
          'code2': code2.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['code1'], equals('foo.ClassA'));
        expect(result['code2'], equals('foo2.ClassB'));
        expect(result['aliasedImports'], hasLength(2));

        final aliases = result['aliasedImports'] as List;
        final aliasMap = {for (var item in aliases) item['uri']: item['alias']};
        expect(aliasMap['package:a/foo.dart'], equals('foo'));
        expect(aliasMap['package:b/foo.dart'], equals('foo2'));
      });

      test('preserves non-Code data unchanged', () {
        final data = {
          'string': 'hello',
          'number': 42,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['string'], equals('hello'));
        expect(result['number'], equals(42));
        expect(result['bool'], isTrue);
        expect(result['list'], equals([1, 2, 3]));
        expect(result['map'], equals({'nested': 'value'}));
        expect(result['aliasedImports'], isEmpty);
      });
    });
    group('Full Rendering', () {
      late AssetReader assetReader;

      setUpAll(() async {
        assetReader = await PackageAssetReader.currentIsolate();
      });

      test('Custom RdfProperty Mapping', () async {
        final data = {
          "header": {
            "sourcePath": "property_processor_test_models.dart",
            "generatedOn": "2025-06-23T15:43:04.426528"
          },
          "broaderImports": {
            "package:rdf_core/src/exceptions/exceptions.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/exceptions/rdf_exception.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/exceptions/rdf_decoder_exception.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/exceptions/rdf_encoder_exception.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/exceptions/rdf_validation_exception.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/graph/rdf_graph.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/graph/rdf_term.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/graph/triple.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/jsonld/jsonld_codec.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/jsonld/jsonld_decoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/jsonld/jsonld_encoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/ntriples/ntriples_codec.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/ntriples/ntriples_decoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/ntriples/ntriples_encoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/plugin/rdf_codec.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/rdf_decoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/rdf_encoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/turtle/turtle_codec.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/turtle/turtle_decoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/turtle/turtle_encoder.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/turtle/turtle_tokenizer.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_core/src/vocab/namespaces.dart":
                "package:rdf_core/rdf_core.dart",
            "package:rdf_mapper/src/api/deserialization_context.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/deserialization_service.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/deserializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/graph_operations.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/resource_builder.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/resource_reader.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/rdf_mapper_registry.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/rdf_mapper_service.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/serialization_context.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/serialization_service.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/api/serializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/codec/rdf_mapper_codec.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/codec/rdf_mapper_string_codec.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/codec_exceptions.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/deserialization_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/deserializer_datatype_mismatch_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/deserializer_not_found_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/property_value_not_found_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/rdf_mapping_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/serialization_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/serializer_not_found_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/exceptions/too_many_property_values_exception.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/iri/extracting_iri_term_deserializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/iri/iri_full_deserializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/iri/iri_full_serializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/iri/iri_id_serializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_deserializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_serializer.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/base_rdf_literal_term_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/bool_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/date_time_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/double_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/int_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/mappers/literal/string_mapper.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper/src/util/namespace.dart":
                "package:rdf_mapper/rdf_mapper.dart",
            "package:rdf_mapper_annotations/src/base/base_mapping.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/base/mapper_ref.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/base/rdf_annotation.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/property/collection.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/property/property.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/property/provides.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/resource/global_resource.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/resource/local_resource.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/term/iri.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_mapper_annotations/src/term/literal.dart":
                "package:rdf_mapper_annotations/rdf_mapper_annotations.dart",
            "package:rdf_vocabularies/src/generated/xsd.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/index.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/id.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/idref.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/ncname.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/nmtoken.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/name.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/byte.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/datetimestamp.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/daytimeduration.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/int.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/integer.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/long.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/negativeinteger.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/nonnegativeinteger.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/nonpositiveinteger.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/normalizedstring.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/positiveinteger.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/short.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/token.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/unsignedbyte.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/unsignedint.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/unsignedlong.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/unsignedshort.dart":
                "package:rdf_vocabularies/xsd.dart",
            "package:rdf_vocabularies/src/generated/xsd/classes/yearmonthduration.dart":
                "package:rdf_vocabularies/xsd.dart",
            "dart:async": "dart:core",
            "dart:collection": "dart:core",
            "dart:_internal": "dart:core"
          },
          "originalImports": {
            "package:rdf_core/rdf_core.dart": "",
            "package:rdf_mapper/rdf_mapper.dart": "",
            "package:rdf_mapper_annotations/rdf_mapper_annotations.dart": "",
            "package:rdf_vocabularies/schema.dart": "",
            "package:rdf_vocabularies/xsd.dart": "",
            "dart:core": ""
          },
          "mappers": [
            {
              "__type__": "ResourceMapperTemplateData",
              "className": {
                "code":
                    "⟨@file:///Users/klaskalass/privat/rdf/rdf_mapper_generator/test/fixtures/property_processor_test_models.dart@⟩IriMappingNamedMapperTest",
                "imports": [
                  "file:///Users/klaskalass/privat/rdf/rdf_mapper_generator/test/fixtures/property_processor_test_models.dart"
                ],
                "__type__": "\$Code\$"
              },
              "mapperClassName": {
                "code":
                    "⟨@asset:test/property_processor_test_models.rdf_mapper.g.dart@⟩IriMappingNamedMapperTestMapper",
                "imports": [
                  "asset:test/property_processor_test_models.rdf_mapper.g.dart"
                ],
                "__type__": "\$Code\$"
              },
              "mapperInterfaceName": {
                "code":
                    "⟨@package:rdf_mapper/rdf_mapper.dart@⟩LocalResourceMapper",
                "imports": ["package:rdf_mapper/rdf_mapper.dart"],
                "__type__": "\$Code\$"
              },
              "termClass": {
                "code": "⟨@package:rdf_core/rdf_core.dart@⟩BlankNodeTerm",
                "imports": ["package:rdf_core/rdf_core.dart"],
                "__type__": "\$Code\$"
              },
              "typeIri": null,
              "hasTypeIri": false,
              "hasIriStrategy": false,
              "hasIriStrategyMapper": false,
              "iriStrategy": null,
              "constructorParameters": [
                {
                  "value": {
                    "name": "authorId",
                    "dartType": {
                      "code": "⟨@dart:core@⟩String",
                      "imports": ["dart:core"],
                      "__type__": "\$Code\$"
                    },
                    "isRequired": true,
                    "isFieldNullable": false,
                    "useOptionalReader": false,
                    "isIriPart": false,
                    "isRdfProperty": true,
                    "isNamed": true,
                    "iriPartName": null,
                    "predicate": {
                      "code":
                          "⟨@package:rdf_vocabularies/src/generated/schema/classes/book.dart@⟩SchemaBook.author",
                      "imports": [
                        "package:rdf_vocabularies/src/generated/schema/classes/book.dart"
                      ],
                      "__type__": "\$Code\$"
                    },
                    "defaultValue": {
                      "code": "null",
                      "imports": [],
                      "__type__": "\$Code\$"
                    },
                    "hasDefaultValue": false,
                    "isRdfValue": false,
                    "isRdfLanguageTag": false
                  },
                  "last": true
                }
              ],
              "nonConstructorFields": [],
              "constructorParametersOrOtherFields": [
                {
                  "value": {
                    "name": "authorId",
                    "dartType": {
                      "code": "⟨@dart:core@⟩String",
                      "imports": ["dart:core"],
                      "__type__": "\$Code\$"
                    },
                    "isRequired": true,
                    "isFieldNullable": false,
                    "useOptionalReader": false,
                    "isIriPart": false,
                    "isRdfProperty": true,
                    "isNamed": true,
                    "iriPartName": null,
                    "predicate": {
                      "code":
                          "⟨@package:rdf_vocabularies/src/generated/schema/classes/book.dart@⟩SchemaBook.author",
                      "imports": [
                        "package:rdf_vocabularies/src/generated/schema/classes/book.dart"
                      ],
                      "__type__": "\$Code\$"
                    },
                    "defaultValue": {
                      "code": "null",
                      "imports": [],
                      "__type__": "\$Code\$"
                    },
                    "hasDefaultValue": false,
                    "isRdfValue": false,
                    "isRdfLanguageTag": false
                  },
                  "last": true
                }
              ],
              "hasNonConstructorFields": false,
              "properties": [
                {
                  "propertyName": "authorId",
                  "isRequired": true,
                  "isFieldNullable": false,
                  "useOptionalSerialization": false,
                  "isRdfProperty": true,
                  "include": true,
                  "predicate": {
                    "code":
                        "⟨@package:rdf_vocabularies/src/generated/schema/classes/book.dart@⟩SchemaBook.author",
                    "imports": [
                      "package:rdf_vocabularies/src/generated/schema/classes/book.dart"
                    ],
                    "__type__": "\$Code\$"
                  },
                  "defaultValue": {
                    "code": "null",
                    "imports": [],
                    "__type__": "\$Code\$"
                  },
                  "hasDefaultValue": false,
                  "includeDefaultsInSerialization": false,
                  "useConditionalSerialization": false
                }
              ],
              "customMappers": [
                {
                  "value": {
                    "mapper": {
                      "type": {
                        "code": "IriTermMapper<String>",
                        "imports": [],
                        "__type__": "\$Code\$"
                      },
                      "fieldName": "_authorIdMapper",
                      "parameterName": "iriMapper",
                      "isConstructorInjected": true,
                    }
                  }
                },
              ],
              "contextProviders": [],
              "hasContextProviders": false,
              "hasMapperConstructorParameters": true,
              "needsReader": true,
              "registerGlobally": true
            }
          ]
        };

        final template = await TemplateRenderer().renderFileTemplate(
            'package:test/property_processor_test_models.dart',
            data,
            assetReader);

        print(template);
      });
    });
  });
}
