import 'package:analyzer/dart/element/element2.dart';

/// Helper class for resolving public library imports by inner (src) file names.

class BroaderImports {
  final Map<String, String> _libsBySrcLibNames;

  BroaderImports(this._libsBySrcLibNames);

  /// Gets the library associated with the provided export name.
  ///
  /// Returns the [LibraryElement2] for the given export [name],
  /// or null if no library was found with that name.
  String? operator [](String name) => _libsBySrcLibNames[name];

  static BroaderImports create(LibraryElement2 libraryElement) {
    final importedLibraries = libraryElement.fragments
        .expand((frag) => frag.importedLibraries2)
        .toList();
    var entries = importedLibraries
        .expand((lib) => _exportedLibraryMappings(lib, lib.identifier));
    var broaderImports = Map.fromEntries(entries);

    return BroaderImports(broaderImports);
  }

  static Iterable<MapEntry<String, String>> _exportedLibraryMappings(
      LibraryElement2 lib, String broaderImportName) {
    return lib.fragments
        .expand((frag) => frag.libraryExports2)
        .expand((exp) => [
              MapEntry<String, String>(
                  (exp.exportedLibrary2?.identifier)!, broaderImportName),
              if (exp.exportedLibrary2 != null)
                ..._exportedLibraryMappings(
                    exp.exportedLibrary2!, broaderImportName)
            ]);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{..._libsBySrcLibNames};
  }
}
