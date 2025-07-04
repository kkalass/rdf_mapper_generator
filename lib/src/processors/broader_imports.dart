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
    return _exportedLibraryMappingsWithVisited(
        lib, broaderImportName, <String>{});
  }

  static Iterable<MapEntry<String, String>> _exportedLibraryMappingsWithVisited(
      LibraryElem lib, String broaderImportName, Set<String> visited) {
    // Prevent infinite recursion by tracking visited libraries
    if (visited.contains(lib.identifier)) {
      return const <MapEntry<String, String>>[];
    }

    // Create a new set that includes the current library to track this path
    final newVisited = Set<String>.from(visited)..add(lib.identifier);

    return lib.exportedLibraries.expand((exp) => [
          MapEntry<String, String>(exp.identifier, broaderImportName),
          ..._exportedLibraryMappingsWithVisited(
              exp, broaderImportName, newVisited)
        ]);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{..._libsBySrcLibNames};
  }
}
