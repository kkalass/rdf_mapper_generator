import 'package:analyzer/dart/element/element2.dart';

/// Helper class for resolving public library imports by exported class names.
/// This is used during code generation to generate proper import statements
/// for referenced classes and their static members.

class LibsByClassName {
  final Map<String, LibraryElement2> _libsByExportedNames;

  LibsByClassName(this._libsByExportedNames);

  /// Gets the library associated with the provided export name.
  ///
  /// Returns the [LibraryElement2] for the given export [name],
  /// or null if no library was found with that name.
  LibraryElement2? operator [](String name) => _libsByExportedNames[name];

  static LibsByClassName create(LibraryElement2 libraryElement) {
    final libs = libraryElement.fragments
        .expand((frag) => frag.importedLibraries2)
        .toList();

    final libsByExportedNames = {
      for (final lib in libs)
        for (final name in lib.exportNamespace.definedNames2.keys) name: lib,
    };
    return LibsByClassName(libsByExportedNames);
  }
}
