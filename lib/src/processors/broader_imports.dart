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
    final libs = libraryElement.fragments
        .expand((frag) => frag.importedLibraries2)
        .toList();
    var entries = libs.expand((lib) => lib.fragments
        .expand((frag) => frag.libraryExports2)
        .map((exp) => MapEntry<String, String>(
            (exp.exportedLibrary2?.identifier)!, lib.identifier)));
    var broaderImports = Map.fromEntries(entries);

    return BroaderImports(broaderImports);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{..._libsBySrcLibNames};
  }
}
