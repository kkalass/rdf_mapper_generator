/// Represents generated code with its import dependencies and type aliases.
///
/// This class manages code generation where types might come from different
/// packages/libraries and need to be properly imported and aliased in the
/// target file to avoid naming conflicts.
class Code {
  static const String typeMarker = '\$Code\$';
  static const String typeProperty = '__type__';

  final String _code;
  final Set<String> _imports; // Import URIs only

  // Special markers to safely identify aliases in code - these are invalid Dart syntax
  static const String _aliasStartMarker = '⟨@';
  static const String _aliasEndMarker = '@⟩';

  Code._(this._code, this._imports);

  Map<String, dynamic> toMap() {
    return {
      'code': _code,
      'imports': _imports.toList(),
      typeProperty: typeMarker,
    };
  }

  static Code fromMap(Map<String, dynamic> map) {
    assert(map[typeProperty] == typeMarker, 'Invalid map for Code: $map');
    return Code._(
      map['code'] as String,
      Set<String>.from(map['imports'] as List<dynamic>),
    );
  }

  /// Creates a Code instance with the given code string and no imports
  Code.literal(String code) : this._(code, {});

  /// Creates a Code instance for a simple value that doesn't require imports
  factory Code.value(String code) => Code.literal(code);

  /// Creates a Code instance for a type reference that may require imports
  factory Code.type(String typeName, {String? importUri}) {
    if (importUri == null) {
      // No import needed - this is a built-in type or already available
      return Code.literal(typeName);
    }

    return Code._('${_wrapImportUri(importUri)}$typeName', {importUri});
  }

  /// Creates a Code instance for a constructor call
  factory Code.constructor(String constructorCall, {String? importUri}) {
    if (importUri == null) {
      return Code.literal(constructorCall);
    }

    // Replace the constructor with the aliased version using markers
    final parts = constructorCall.split('(');
    if (parts.length >= 2) {
      final constructorPart = parts[0].trim();
      final remainder = parts.sublist(1).join('(');

      String aliasedConstructor;
      if (constructorPart.startsWith('const ')) {
        // Handle const constructors: "const MyClass" or "const MyClass.named"
        final constructorName = constructorPart.substring(6); // Remove "const "
        aliasedConstructor =
            'const ${_wrapImportUri(importUri)}$constructorName';
      } else {
        // Handle regular constructors: "MyClass" or "MyClass.named"
        aliasedConstructor = '${_wrapImportUri(importUri)}$constructorPart';
      }

      final aliasedCode = '$aliasedConstructor($remainder';
      return Code._(aliasedCode, {importUri});
    }

    return Code.literal(constructorCall);
  }

  /// Combines multiple Code instances, merging their imports
  factory Code.combine(List<Code> codes, {String separator = ''}) {
    if (codes.isEmpty) return Code.literal('');
    if (codes.length == 1) return codes.first;

    final combinedImports = codes.expand((c) => c._imports).toSet();

    // Second pass: build the combined code by resolving each code with the alias mapping
    String combinedCode = codes.map((c) => c._code).join(separator);

    return Code._(combinedCode, combinedImports);
  }

  /// The generated code string
  String get code => resolveAliases().$1;

  /// All import dependencies required by this code
  Set<String> get imports => Set.unmodifiable(_imports);

  /// Checks if this code has any import dependencies
  bool get hasImports => _imports.isNotEmpty;

  /// Resolves alias markers in code to actual aliases
  /// Returns a record with the resolved code and a map of import URIs to aliases
  (String, Map<String, String>) resolveAliases(
      {Map<String, String> knownImports = const {},
      Map<String, String> broaderImports = const {}}) {
    String resolvedCode = _code;
    final importsWithAlias = <String, String>{};

    // Track which aliases are already used to avoid conflicts
    final usedAliases = <String>{};
    usedAliases.addAll(knownImports.values);

    for (final originalImportUri in _imports) {
      final importUri = broaderImports[originalImportUri] ?? originalImportUri;
      String alias;

      if (knownImports.containsKey(importUri)) {
        // Use the known alias
        alias = knownImports[importUri]!;
      } else {
        // Generate a new alias, ensuring it doesn't conflict
        alias = _generateAliasFromUri(importUri);
        if (alias.isNotEmpty) {
          int counter = 2;
          while (usedAliases.contains(alias)) {
            alias = '${_generateAliasFromUri(importUri)}$counter';
            counter++;
          }
        }
        usedAliases.add(alias);
      }

      importsWithAlias[importUri] = alias;
      final marker = _wrapImportUri(originalImportUri);
      resolvedCode =
          resolvedCode.replaceAll(marker, alias.isEmpty ? '' : '$alias.');
    }

    return (resolvedCode, importsWithAlias);
  }

  /// Generates a default alias from an import URI
  static String _generateAliasFromUri(String uri) {
    if (uri.startsWith('package:') ||
        uri.startsWith('asset:') ||
        uri.startsWith('file:')) {
      // Extract filename from URI: package:foo/bar/baz.dart -> baz, asset:foo/bar.dart -> bar
      final prefixLength = uri.split(":")[0].length + 1; // +1 for the colon
      final parts = uri.substring(prefixLength).split('/');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        // Remove .dart extension if present
        final aliasName = lastPart.endsWith('.dart')
            ? lastPart.substring(0, lastPart.length - 5)
            : lastPart;
        return _sanitizeAlias(aliasName);
      }
    } else if (uri.startsWith('dart:')) {
      if (uri == 'dart:core') {
        // Special case for dart:core - no alias needed
        return '';
      }
      // dart:core -> core
      return _sanitizeAlias(uri.substring(5));
    }

    // Fallback: use a generic alias
    return 'lib${uri.hashCode.abs()}';
  }

  /// Wraps an import URI with special markers for safe replacement
  static String _wrapImportUri(String importUri) {
    return '$_aliasStartMarker$importUri$_aliasEndMarker';
  }

  /// Sanitizes an alias to ensure it's a valid Dart identifier
  /// If the result is too long, shortens it by using first letters of underscore-separated parts
  static String _sanitizeAlias(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    // If alias is reasonably short, return as is
    if (sanitized.length <= 12) {
      return sanitized;
    }

    // For long aliases, use first letter of each underscore-separated part
    final parts = sanitized.split('_').where((part) => part.isNotEmpty);
    if (parts.length > 1) {
      final abbreviated = parts.map((part) => part[0].toLowerCase()).join();
      return abbreviated.isNotEmpty ? abbreviated : sanitized;
    }

    // For single long words without underscores, truncate to reasonable length
    return sanitized.length > 12 ? sanitized.substring(0, 12) : sanitized;
  }

  @override
  String toString() => _code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Code &&
          runtimeType == other.runtimeType &&
          _code == other._code &&
          _setsEqual(_imports, other._imports);

  @override
  int get hashCode => _code.hashCode ^ _imports.hashCode;

  static bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }
}
