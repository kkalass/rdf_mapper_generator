/// Represents generated code with its import dependencies and type aliases.
///
/// This class manages code generation where types might come from different
/// packages/libraries and need to be properly imported and aliased in the
/// target file to avoid naming conflicts.
class Code {
  final String _code;
  final Map<String, ImportInfo> _imports;

  Code._(this._code, this._imports);

  /// Creates a Code instance with the given code string and no imports
  Code.literal(String code) : this._(code, {});

  /// Creates a Code instance for a simple value that doesn't require imports
  factory Code.value(String code) => Code.literal(code);

  /// Creates a Code instance for a type reference that may require imports
  factory Code.type(String typeName, {String? importUri, String? alias}) {
    if (importUri == null) {
      // No import needed - this is a built-in type or already available
      return Code.literal(typeName);
    }

    final imports = <String, ImportInfo>{};
    final effectiveAlias = alias ?? _generateAliasFromUri(importUri);
    imports[importUri] = ImportInfo(uri: importUri, alias: effectiveAlias);

    // Replace the type name with the aliased version
    final aliasedCode = typeName.contains('.')
        ? typeName.replaceFirst(typeName.split('.').first, effectiveAlias)
        : '$effectiveAlias.$typeName';

    return Code._(aliasedCode, imports);
  }

  /// Creates a Code instance for a constructor call
  factory Code.constructor(String constructorCall,
      {String? importUri, String? alias}) {
    if (importUri == null) {
      return Code.literal(constructorCall);
    }

    final imports = <String, ImportInfo>{};
    final effectiveAlias = alias ?? _generateAliasFromUri(importUri);
    imports[importUri] = ImportInfo(uri: importUri, alias: effectiveAlias);

    // Replace the constructor with the aliased version
    final parts = constructorCall.split('(');
    if (parts.length >= 2) {
      final constructorName = parts[0];
      final remainder = parts.sublist(1).join('(');
      final aliasedConstructor = constructorName.contains('.')
          ? constructorName.replaceFirst(
              constructorName.split('.').first, effectiveAlias)
          : '$effectiveAlias.$constructorName';
      final aliasedCode = '$aliasedConstructor($remainder';
      return Code._(aliasedCode, imports);
    }

    return Code.literal(constructorCall);
  }

  /// Combines multiple Code instances, merging their imports
  factory Code.combine(List<Code> codes, {String separator = ''}) {
    if (codes.isEmpty) return Code.literal('');
    if (codes.length == 1) return codes.first;

    final combinedCode = codes.map((c) => c._code).join(separator);
    final combinedImports = <String, ImportInfo>{};

    for (final code in codes) {
      combinedImports.addAll(code._imports);
    }

    return Code._(combinedCode, combinedImports);
  }

  /// The generated code string
  String get code => _code;

  /// All import dependencies required by this code
  Map<String, ImportInfo> get imports => Map.unmodifiable(_imports);

  /// Checks if this code has any import dependencies
  bool get hasImports => _imports.isNotEmpty;

  /// Maps the internal aliases to target aliases used in the generated file
  ///
  /// [aliasMapping] maps from import URI to the alias used in the target file
  Code mapAliases(Map<String, String> aliasMapping) {
    if (_imports.isEmpty) return this;

    String mappedCode = _code;

    for (final entry in _imports.entries) {
      final importUri = entry.key;
      final currentAlias = entry.value.alias;
      final targetAlias = aliasMapping[importUri];

      if (targetAlias != null && currentAlias != targetAlias) {
        // Replace the current alias with the target alias in the code
        final pattern = RegExp(r'\b' + RegExp.escape(currentAlias) + r'\b');
        mappedCode = mappedCode.replaceAll(pattern, targetAlias);
      }
    }

    return Code._(mappedCode, _imports);
  }

  /// Generates a default alias from an import URI
  static String _generateAliasFromUri(String uri) {
    if (uri.startsWith('package:')) {
      // Extract package name: package:foo/bar.dart -> foo
      final parts = uri.substring(8).split('/');
      if (parts.isNotEmpty) {
        return _sanitizeAlias(parts.first);
      }
    } else if (uri.startsWith('dart:')) {
      // dart:core -> core
      return _sanitizeAlias(uri.substring(5));
    }

    // Fallback: use a generic alias
    return 'lib${uri.hashCode.abs()}';
  }

  /// Sanitizes an alias to ensure it's a valid Dart identifier
  static String _sanitizeAlias(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  @override
  String toString() => _code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Code &&
          runtimeType == other.runtimeType &&
          _code == other._code &&
          _mapsEqual(_imports, other._imports);

  @override
  int get hashCode => _code.hashCode ^ _imports.hashCode;

  static bool _mapsEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
}

/// Information about an import dependency
class ImportInfo {
  final String uri;
  final String alias;

  const ImportInfo({
    required this.uri,
    required this.alias,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportInfo &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          alias == other.alias;

  @override
  int get hashCode => uri.hashCode ^ alias.hashCode;

  @override
  String toString() => 'ImportInfo(uri: $uri, alias: $alias)';
}
