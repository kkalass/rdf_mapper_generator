import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/models/global_resource_info.dart';

/// Processes IRI strategy templates and extracts variable information.
///
/// This processor analyzes IRI templates used in @RdfGlobalResource annotations
/// to extract variables, validate patterns, and categorize variables by their source.
class IriStrategyProcessor {
  /// Processes an IRI template and extracts information about variables and validation.
  ///
  /// Returns an [IriTemplateInfo] containing parsed template data, or null if the
  /// template is invalid or empty.
  static IriTemplateInfo? processTemplate(
      String? template, ClassElement2 classElement) {
    if (template == null || template.isEmpty) {
      return null;
    }

    try {
      final variables = _extractVariables(template);
      final propertyResult = _findPropertyVariables(variables, classElement);
      final contextVariables = Set.unmodifiable(variables.difference(
          propertyResult.propertyVariables.map((pn) => pn.name).toSet()));
      final validationResult = _validateTemplate(template, variables);

      return IriTemplateInfo(
        template: template,
        variables: variables,
        propertyVariables: propertyResult.propertyVariables,
        contextVariables: contextVariables,
        isValid: validationResult.isValid,
        validationErrors: validationResult.errors,
        warnings: propertyResult.warnings,
      );
    } catch (e) {
      return IriTemplateInfo(
        template: template,
        variables: Set.unmodifiable(<String>{}),
        propertyVariables: Set.unmodifiable(<PropertyVariableName>{}),
        contextVariables: Set.unmodifiable(<String>{}),
        isValid: false,
        validationErrors: ['Failed to process template: $e'],
        warnings: [],
      );
    }
  }

  /// Extracts all variable names from an IRI template.
  ///
  /// Variables are identified by the pattern {variableName} or {+variableName} in the template.
  /// The + prefix ( reserved expansion) is stripped from the variable name.
  /// Returns a set of unique variable names.
  static Set<String> _extractVariables(String template) {
    final variables = <String>{};
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(template);

    for (final match in matches) {
      final variableName = match.group(1);
      if (variableName != null && variableName.isNotEmpty) {
        // Strip the + prefix for RFC 6570 reserved expansion
        final cleanVariableName = variableName.startsWith('+')
            ? variableName.substring(1)
            : variableName;
        variables.add(cleanVariableName);
      }
    }

    return Set.unmodifiable(variables);
  }

  /// Identifies which variables correspond to properties annotated with @RdfIriPart.
  ///
  /// Scans the class element for fields with @RdfIriPart annotations and matches
  /// them against the extracted variables. Also detects unused @RdfIriPart annotations
  /// that don't correspond to any template variable.
  static _PropertyVariablesResult _findPropertyVariables(
      Set<String> variables, ClassElement2 classElement) {
    final propertyVariables = <PropertyVariableName>{};
    final warnings = <String>[];

    for (final field in classElement.fields2) {
      if (field.isStatic || field.isSynthetic) continue;

      // Check for @RdfIriPart annotation
      DartObject? iriPartAnnotation;
      for (final elementAnnotation in field.metadata2.annotations) {
        try {
          final annotation = elementAnnotation.computeConstantValue();
          if (annotation != null) {
            final name = annotation.type?.element3?.name3;
            if (name == 'RdfIriPart') {
              iriPartAnnotation = annotation;
              break;
            }
          }
        } catch (_) {
          // Ignore errors for individual annotations
          continue;
        }
      }

      if (iriPartAnnotation != null) {
        // Try to get the variable name from the annotation,
        // fallback to field name if not specified
        String name = field.name3!;

        final annotationValue = iriPartAnnotation;
        // Check for named parameter in @RdfIriPart(name)
        final nameField = annotationValue.getField('name');
        if (nameField != null && !nameField.isNull) {
          final nameValue = nameField.toStringValue();
          if (nameValue != null && nameValue.isNotEmpty) {
            name = nameValue;
          }
        }

        // Add to property variables if it matches a template variable
        if (variables.contains(name)) {
          propertyVariables.add(
              PropertyVariableName(name: name, dartPropertyName: field.name3!));
        } else {
          // Generate warning for unused @RdfIriPart annotation
          warnings.add(
              'Property \'${field.name3}\' is annotated with @RdfIriPart(\'$name\') but \'$name\' is not used in the IRI template');
        }
      }
    }

    return _PropertyVariablesResult(
      propertyVariables: Set.unmodifiable(propertyVariables),
      warnings: warnings,
    );
  }

  /// Validates an IRI template for correctness and common issues.
  ///
  /// Checks for:
  /// - Valid URI syntax when variables are substituted
  /// - Proper variable syntax
  /// - No unescaped special characters
  /// - Reasonable URI structure
  static _TemplateValidationResult _validateTemplate(
      String template, Set<String> variables) {
    final errors = <String>[];

    // Check for basic template syntax issues
    if (!_hasValidVariableSyntax(template)) {
      errors.add(
          'Invalid variable syntax. Variables must be in format {variableName}');
    }

    // Check for unmatched braces
    if (!_hasMatchedBraces(template)) {
      errors.add('Unmatched braces in template');
    }

    // Validate as URI template by substituting variables with dummy values
    final testUri = _createTestUri(template, variables);
    if (!_isValidUriStructure(testUri)) {
      errors.add('Template does not produce valid URI structure');
    }

    // Check for forbidden characters in variable names
    for (final variable in variables) {
      if (!_isValidVariableName(variable)) {
        errors.add(
            'Invalid variable name: $variable. Variable names must be valid identifiers');
      }
    }

    // Warn about relative URIs (might be intentional)
    // Templates starting with {+variable} are valid if the variable contains a complete URI
    final startsWithReservedExpansion =
        RegExp(r'^\{\+\w+\}').hasMatch(template);
    if (!template.contains('://') &&
        !template.startsWith('/') &&
        !template.startsWith('urn:') &&
        !startsWithReservedExpansion) {
      errors.add(
          'Template appears to be a relative URI. Consider using absolute URIs for global resources');
    }

    return _TemplateValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Checks if the template has valid variable syntax.
  /// Supports both {variable} and {+variable} patterns (RFC 6570).
  static bool _hasValidVariableSyntax(String template) {
    // Check for invalid patterns like {{, }}, {}, { }, etc.
    final invalidPatterns = [
      RegExp(r'\{\{'), // Double opening brace
      RegExp(r'\}\}'), // Double closing brace
      RegExp(r'\{\s*\}'), // Empty braces or braces with only whitespace
      RegExp(r'\{\+\s*\}'), // Empty braces with + prefix
      RegExp(
          r'\{[^a-zA-Z_+][^}]*\}'), // Variables not starting with letter, underscore, or +
      RegExp(
          r'\{\+[^a-zA-Z_][^}]*\}'), // Variables with + not followed by letter or underscore
    ];

    return !invalidPatterns.any((pattern) => pattern.hasMatch(template));
  }

  /// Checks if all braces in the template are properly matched.
  static bool _hasMatchedBraces(String template) {
    int braceCount = 0;

    for (int i = 0; i < template.length; i++) {
      if (template[i] == '{') {
        braceCount++;
      } else if (template[i] == '}') {
        braceCount--;
        if (braceCount < 0) {
          return false; // Closing brace without opening
        }
      }
    }

    return braceCount == 0; // All braces matched
  }

  /// Creates a test URI by substituting variables with dummy values.
  /// Handles both regular {variable} and RFC 6570 {+variable} patterns.
  static String _createTestUri(String template, Set<String> variables) {
    String testUri = template;

    for (final variable in variables) {
      // Replace {+variable} patterns with a complete URI for reserved expansion
      testUri = testUri.replaceAll('{+$variable}', 'https://example.org');
      // Replace regular {variable} patterns with simple test values
      testUri = testUri.replaceAll('{$variable}', 'test_value');
    }

    return testUri;
  }

  /// Validates that the test URI has a reasonable structure.
  static bool _isValidUriStructure(String testUri) {
    try {
      final uri = Uri.parse(testUri);

      // Basic validation - should have scheme or be absolute path
      if (uri.scheme.isEmpty && !testUri.startsWith('/')) {
        return false;
      }

      // Check for obviously invalid patterns
      if (testUri.contains('//') && !testUri.contains('://')) {
        return false; // Double slashes not following scheme
      }

      // Check for consecutive slashes after the scheme
      if (testUri.contains('://')) {
        final afterScheme = testUri.substring(testUri.indexOf('://') + 3);
        if (afterScheme.contains('//')) {
          return false; // Multiple consecutive slashes in path
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates that a variable name is a valid identifier.
  static bool _isValidVariableName(String variable) {
    // Must start with letter or underscore, followed by letters, digits, or underscores
    final regex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return regex.hasMatch(variable) && variable.isNotEmpty;
  }
}

/// Internal model for template validation results.
class _TemplateValidationResult {
  final bool isValid;
  final List<String> errors;

  const _TemplateValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// Internal model for property variable analysis results.
class _PropertyVariablesResult {
  final Set<PropertyVariableName> propertyVariables;
  final List<String> warnings;

  const _PropertyVariablesResult({
    required this.propertyVariables,
    required this.warnings,
  });
}
