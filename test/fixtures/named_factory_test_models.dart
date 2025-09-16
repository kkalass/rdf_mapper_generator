import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Configuration class for factory patterns
class IriMapperConfig {
  final String baseUri;
  final String format;

  const IriMapperConfig({
    required this.baseUri,
    this.format = 'standard',
  });
}

/// Factory function for simple IRI mapping without config
String Function<T extends SimpleBook>() simpleBookIriFactory() {
  return <T extends SimpleBook>() {
    // This would typically return an IRI string for the book
    return 'https://example.com/books/${(T as SimpleBook).id}';
  };
}

/// Factory function for complex IRI mapping with config
String Function<T extends ConfigurableBook>(IriMapperConfig config)
    configurableBookIriFactory() {
  return <T extends ConfigurableBook>(IriMapperConfig config) {
    // This would use the config to determine the IRI format
    final book = T as ConfigurableBook;
    return '${config.baseUri}/books/${book.id}?format=${config.format}';
  };
}

/// Test model with namedFactory without config
@RdfGlobalResource(
  IriTerm.prevalidated('http://example.com/Book'),
  IriStrategy.namedFactory(
    'simpleBookIriFactory',
  ),
)
class SimpleBook {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm.prevalidated('http://example.com/title'))
  final String title;

  const SimpleBook({
    required this.id,
    required this.title,
  });
}

/// Test model with namedFactory with config
@RdfGlobalResource(
  IriTerm.prevalidated('http://example.com/ConfigurableBook'),
  IriStrategy.namedFactory(
    'configurableBookIriFactory',
    IriMapperConfig(
      baseUri: 'https://books.example.com',
      format: 'detailed',
    ),
  ),
)
class ConfigurableBook {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm.prevalidated('http://example.com/title'))
  final String title;

  @RdfProperty(IriTerm.prevalidated('http://example.com/author'))
  final String author;

  const ConfigurableBook({
    required this.id,
    required this.title,
    required this.author,
  });
}

/// Test model with registerGlobally: false and namedFactory
@RdfGlobalResource(
  IriTerm.prevalidated('http://example.com/LocalBook'),
  IriStrategy.namedFactory(
    'simpleBookIriFactory',
  ),
  registerGlobally: false,
)
class LocalBook {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm.prevalidated('http://example.com/title'))
  final String title;

  const LocalBook({
    required this.id,
    required this.title,
  });
}

/// Test model combining namedFactory with context providers
@RdfGlobalResource(
  IriTerm.prevalidated('http://example.com/ContextualBook'),
  IriStrategy.namedFactory(
    'configurableBookIriFactory',
    IriMapperConfig(
      baseUri: 'https://contextual.example.com',
      format: 'contextual',
    ),
  ),
)
class ContextualBook {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm.prevalidated('http://example.com/title'))
  final String title;

  @RdfProperty(IriTerm.prevalidated('http://example.com/baseUri'))
  final String Function() baseUriProvider;

  const ContextualBook({
    required this.id,
    required this.title,
    required this.baseUriProvider,
  });
}
