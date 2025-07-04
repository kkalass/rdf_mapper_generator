// import 'package:analyzer/dart/element/element2.dart';

import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';

/// Helper class for resolving public library imports by inner (src) file names.

class BroaderImports {
  final Map<String, String> _libsBySrcLibNames;

  BroaderImports(this._libsBySrcLibNames);

  /// Gets the library associated with the provided export name.
  ///
  /// Returns the [LibraryElem] for the given export [name],
  /// or null if no library was found with that name.
  String? operator [](String name) => _libsBySrcLibNames[name];

  static BroaderImports create(LibraryElem libraryElement) {
    final importedLibraries = libraryElement.importedLibraries;
    var entries = importedLibraries
        .expand((lib) => _exportedLibraryMappings(lib, lib.identifier));
    var broaderImports = Map.fromEntries(entries);

    return BroaderImports(broaderImports);
  }

  static Iterable<MapEntry<String, String>> _exportedLibraryMappings(
      LibraryElem lib, String broaderImportName) {
    return lib.exportedLibraries.expand((exp) => [
          MapEntry<String, String>(exp.identifier, broaderImportName),
          ..._exportedLibraryMappings(exp, broaderImportName)
        ]);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{..._libsBySrcLibNames};
  }
}
