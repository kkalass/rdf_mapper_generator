import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies/xsd.dart';

@RdfLiteral()
class LiteralString {
  @RdfValue()
  final String foo;
  LiteralString({
    required this.foo,
  });
}

@RdfLiteral()
class Rating {
  @RdfValue() // Marks this property as the source for the literal value
  final int stars;

  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;

  @RdfLanguageTag()
  final String language;

  LocalizedText(
    this.text,
    this.language,
  );
}

@RdfLiteral(Xsd.double)
class LiteralDouble {
  @RdfValue()
  final double foo;
  LiteralDouble({
    required this.foo,
  });
}

@RdfLiteral(Xsd.integer)
class LiteralInteger {
  @RdfValue()
  final int value;
  LiteralInteger({
    required this.value,
  });
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
)
class Temperature {
  final double celsius;

  Temperature(this.celsius);

  // Instance method for serialization
  LiteralTerm formatCelsius() => LiteralTerm('$celsius°C');

  // Static method for deserialization
  static Temperature parse(LiteralTerm term) =>
      Temperature(double.parse(term.value.replaceAll('°C', '')));
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'toRdf',
  fromLiteralTermMethod: 'fromRdf',
)
class CustomLocalizedText {
  final String text;
  final String language;
  CustomLocalizedText(this.text, this.language);

  // Instance method for serialization
  LiteralTerm toRdf() => LiteralTerm.withLanguage(text, language);

  // Static method for deserialization
  static CustomLocalizedText fromRdf(LiteralTerm term) =>
      CustomLocalizedText(term.value, term.language ?? 'en');
}

// FIXME: Fix the rdf_mapper_annotations package to not include the datatype for custom constructor
// FIXME: fix the RdfLiteral.custom examples where a String is used instead of a LiteralTerm.
@RdfLiteral.custom(
  toLiteralTermMethod: 'toMilliunit',
  fromLiteralTermMethod: 'fromMilliunit',
)
class DoubleAsMilliunit {
  final double value;

  DoubleAsMilliunit(this.value);

  // Instance method for serialization
  LiteralTerm toMilliunit() =>
      LiteralTerm((value * 1000).round().toString(), datatype: Xsd.int);

  // Static method for deserialization
  static DoubleAsMilliunit fromMilliunit(LiteralTerm term) =>
      DoubleAsMilliunit(int.parse(term.value) / 1000.0);
}

@RdfLiteral.namedMapper('testLiteralMapper')
class LiteralWithNamedMapper {
  final String value;

  LiteralWithNamedMapper(this.value);
}

@RdfLiteral.mapper(TestLiteralMapper)
class LiteralWithMapper {
  final String value;

  LiteralWithMapper(this.value);
}

@RdfLiteral.mapperInstance(TestLiteralMapper2())
class LiteralWithMapperInstance {
  final String value;

  LiteralWithMapperInstance(this.value);
}

class TestLiteralMapper implements LiteralTermMapper<LiteralWithMapper> {
  const TestLiteralMapper();

  @override
  LiteralWithMapper fromRdfTerm(
      LiteralTerm term, DeserializationContext context) {
    return LiteralWithMapper(term.value);
  }

  @override
  LiteralTerm toRdfTerm(LiteralWithMapper value, SerializationContext context) {
    return LiteralTerm(value.value);
  }
}

class TestLiteralMapper2
    implements LiteralTermMapper<LiteralWithMapperInstance> {
  const TestLiteralMapper2();

  @override
  LiteralWithMapperInstance fromRdfTerm(
      LiteralTerm term, DeserializationContext context) {
    return LiteralWithMapperInstance(term.value);
  }

  @override
  LiteralTerm toRdfTerm(
      LiteralWithMapperInstance value, SerializationContext context) {
    return LiteralTerm(value.value);
  }
}
