// Test functions that are embedded in the generated code.
// This file is not really high-tech, but more of a debugging tool to ensure
// that the generated code works as expected.

import 'package:test/test.dart';

/// Parses IRI parts from a complete IRI using a template.
///
/// Supports RFC 6570 URI Template standard:
/// - {variable} (default): excludes reserved characters like '/'
/// - {+variable}: includes reserved characters for URLs/paths (RFC 6570 Level 2)
Map<String, String> _parseIriParts(
    String iri, String template, List<String> variables) {
  try {
    // Handle edge cases
    if (template.isEmpty || iri.isEmpty || variables.isEmpty) return {};

    // Check for malformed templates
    if (template.split('{').length != template.split('}').length) return {};

    // Convert template to regex by replacing variables with capture groups
    String regexPattern = template;
    final variableOrder = <String>[];

    // Replace variables in the order they appear in the template
    for (final variable in variables) {
      final reservedPattern = '{+$variable}';
      final defaultPattern = '{$variable}';

      if (regexPattern.contains(reservedPattern)) {
        variableOrder.add(variable);
        regexPattern =
            regexPattern.replaceFirst(reservedPattern, '___CAPTURE_GROUP___');
      } else if (regexPattern.contains(defaultPattern)) {
        variableOrder.add(variable);
        regexPattern =
            regexPattern.replaceFirst(defaultPattern, '___CAPTURE_GROUP___');
      }
    }

    // Check if we found all variables
    if (variableOrder.length != variables.length) return {};

    // Escape special regex characters
    regexPattern = RegExp.escape(regexPattern);

    // Now replace capture group placeholders with actual regex patterns
    for (int i = 0; i < variableOrder.length; i++) {
      final variable = variableOrder[i];
      final isReserved = template.contains('{+$variable}');

      if (isReserved) {
        // Reserved expansion: greedy match that includes '/'
        regexPattern = regexPattern.replaceFirst(
            RegExp.escape('___CAPTURE_GROUP___'), '(.*?)');
      } else {
        // Default expansion: match non-'/' characters
        regexPattern = regexPattern.replaceFirst(
            RegExp.escape('___CAPTURE_GROUP___'), '([^/]*?)');
      }
    }

    // Handle the special case where default variables might need to include ':'
    // in URL schemes (like https://). We need to make the regex smarter.

    // For now, let's use a different approach - match greedily but validate after
    final parts = <String, String>{};

    // Try regex first
    final regex = RegExp('^$regexPattern\$');
    final match = regex.firstMatch(iri);

    if (match != null && match.groupCount == variableOrder.length) {
      // Extract values
      for (int i = 0; i < variableOrder.length; i++) {
        final variable = variableOrder[i];
        final value = match.group(i + 1) ?? '';
        final isReserved = template.contains('{+$variable}');

        // Validate that default variables don't contain '/' unless it's a URL scheme
        if (!isReserved && value.contains('/') && !value.contains('://')) {
          // This default variable contains '/' which it shouldn't
          // Fall back to manual parsing
          return _parseManually(iri, template, variables);
        }

        parts[variable] = value;
      }

      return parts;
    }

    // Regex failed, try manual parsing
    return _parseManually(iri, template, variables);
  } catch (e) {
    return {};
  }
}

/// Manual parsing approach for complex cases
Map<String, String> _parseManually(
    String iri, String template, List<String> variables) {
  try {
    final parts = <String, String>{};

    // Build a list of template segments
    final segments = <dynamic>[];
    String remaining = template;

    while (remaining.isNotEmpty) {
      final varStart = remaining.indexOf('{');
      if (varStart == -1) {
        // No more variables
        if (remaining.isNotEmpty) {
          segments.add(remaining); // literal
        }
        break;
      }

      // Add literal before variable
      if (varStart > 0) {
        segments.add(remaining.substring(0, varStart));
      }

      // Find variable end
      final varEnd = remaining.indexOf('}', varStart);
      if (varEnd == -1) return {}; // malformed

      final varContent = remaining.substring(varStart + 1, varEnd);
      final isReserved = varContent.startsWith('+');
      final varName = isReserved ? varContent.substring(1) : varContent;

      if (variables.contains(varName)) {
        segments.add({
          'name': varName,
          'isReserved': isReserved,
        });
      }

      remaining = remaining.substring(varEnd + 1);
    }

    // Now parse the IRI segment by segment
    String currentIri = iri;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (segment is String) {
        // Literal segment
        if (!currentIri.startsWith(segment)) {
          return {}; // doesn't match
        }
        currentIri = currentIri.substring(segment.length);
      } else if (segment is Map) {
        // Variable segment
        final varName = segment['name'] as String;
        final isReserved = segment['isReserved'] as bool;

        // Find the next literal to know where this variable ends
        String? nextLiteral;
        for (int j = i + 1; j < segments.length; j++) {
          if (segments[j] is String) {
            nextLiteral = segments[j] as String;
            break;
          }
        }

        String varValue;
        if (nextLiteral != null) {
          // Find the next occurrence of the literal
          int nextIndex = currentIri.indexOf(nextLiteral);
          if (nextIndex == -1) return {};

          // For default variables, find the last occurrence before a '/'
          // unless it's part of a URL scheme
          if (!isReserved) {
            // Look for alternative positions that don't cross path boundaries
            final allIndices = <int>[];
            int searchPos = 0;
            while (searchPos < currentIri.length) {
              final foundIndex = currentIri.indexOf(nextLiteral, searchPos);
              if (foundIndex == -1) break;
              allIndices.add(foundIndex);
              searchPos = foundIndex + 1;
            }

            // Pick the first valid index where the variable value doesn't contain '/'
            // unless it's a URL scheme
            bool foundValid = false;
            for (final index in allIndices) {
              final candidateValue = currentIri.substring(0, index);
              if (!candidateValue.contains('/') ||
                  candidateValue.contains('://')) {
                nextIndex = index;
                foundValid = true;
                break;
              }
            }

            if (!foundValid && !allIndices.isEmpty) {
              // Use the first occurrence as fallback
              nextIndex = allIndices.first;
            }
          }

          varValue = currentIri.substring(0, nextIndex);
          currentIri = currentIri.substring(nextIndex);
        } else {
          // Last variable, take everything remaining
          varValue = currentIri;
          currentIri = '';
        }

        parts[varName] = varValue;
      }
    }

    // Should have consumed all input
    if (currentIri.isNotEmpty) return {};

    // Should have found all variables
    if (parts.length != variables.length) return {};

    return parts;
  } catch (e) {
    return {};
  }
}

void main() {
  group('_parseIriParts', () {
    test('should parse basic IRI with baseUri and id', () {
      final iriParts = _parseIriParts('https://my.host.de/test/persons/234',
          '{+baseUri}/persons/{thisId}', ['baseUri', 'thisId']);

      expect(iriParts['thisId'], '234');
      expect(iriParts['baseUri'], 'https://my.host.de/test');
    });

    test('should parse IRI with multiple path segments in baseUri', () {
      final iriParts = _parseIriParts(
          'https://api.example.com/v1/data/users/123',
          '{+baseUri}/users/{id}',
          ['baseUri', 'id']);

      expect(iriParts['id'], '123');
      expect(iriParts['baseUri'], 'https://api.example.com/v1/data');
    });

    test('should parse IRI with single variable', () {
      final iriParts = _parseIriParts('user123', '{userId}', ['userId']);

      expect(iriParts['userId'], 'user123');
    });

    test('should parse IRI with variable at the beginning', () {
      final iriParts = _parseIriParts(
          'admin/settings/theme', '{role}/settings/theme', ['role']);

      expect(iriParts['role'], 'admin');
    });

    test('should parse IRI with variable in the middle', () {
      final iriParts = _parseIriParts(
          'api/v2/products', 'api/{version}/products', ['version']);

      expect(iriParts['version'], 'v2');
    });

    test('should parse IRI with multiple variables', () {
      final iriParts = _parseIriParts(
          'https://example.com/users/john/posts/42',
          '{+base}/users/{username}/posts/{postId}',
          ['base', 'username', 'postId']);

      expect(iriParts['base'], 'https://example.com');
      expect(iriParts['username'], 'john');
      expect(iriParts['postId'], '42');
    });

    test('should parse IRI with consecutive variables', () {
      // Note: This is inherently ambiguous - we need at least one separator
      // Testing with a dot separator to make it unambiguous
      final iriParts = _parseIriParts(
          'file123.txt', '{name}.{extension}', ['name', 'extension']);

      expect(iriParts['name'], 'file123');
      expect(iriParts['extension'], 'txt');
    });

    test('should parse IRI with numeric IDs', () {
      final iriParts = _parseIriParts('https://db.example.com/records/999999',
          '{+baseUrl}/records/{recordId}', ['baseUrl', 'recordId']);

      expect(iriParts['baseUrl'], 'https://db.example.com');
      expect(iriParts['recordId'], '999999');
    });

    test('should parse IRI with UUID-like IDs', () {
      final iriParts = _parseIriParts(
          'https://api.service.com/entities/550e8400-e29b-41d4-a716-446655440000',
          '{+baseUri}/entities/{entityId}',
          ['baseUri', 'entityId']);

      expect(iriParts['baseUri'], 'https://api.service.com');
      expect(iriParts['entityId'], '550e8400-e29b-41d4-a716-446655440000');
    });

    test('should parse IRI with special characters in ID', () {
      final iriParts = _parseIriParts('https://example.com/items/item-name_123',
          '{+base}/items/{itemId}', ['base', 'itemId']);

      expect(iriParts['base'], 'https://example.com');
      expect(iriParts['itemId'], 'item-name_123');
    });

    test('should handle IRI with query parameters (not in template)', () {
      final iriParts = _parseIriParts(
          'https://example.com/users/123?format=json',
          '{+baseUri}/users/{userId}',
          ['baseUri', 'userId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['userId'], '123?format=json');
    });

    test('should handle IRI with fragment (not in template)', () {
      final iriParts = _parseIriParts('https://example.com/docs/page#section1',
          '{+baseUri}/docs/{pageId}', ['baseUri', 'pageId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['pageId'], 'page#section1');
    });
    test('should handle IRI with fragment (in template)', () {
      final iriParts = _parseIriParts('https://example.com/docs/page#section1',
          '{+baseUri}/docs/{pageId}#section1', ['baseUri', 'pageId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['pageId'], 'page');
    });

    test('should return empty map when IRI does not match template', () {
      final iriParts = _parseIriParts('https://example.com/different/structure',
          '{baseUri}/users/{userId}', ['baseUri', 'userId']);

      expect(iriParts, isEmpty);
    });

    test('should return empty map when template has more segments than IRI',
        () {
      final iriParts = _parseIriParts('https://example.com/users',
          '{+baseUri}/users/{userId}/profile', ['baseUri', 'userId']);

      expect(iriParts, isEmpty);
    });

    test('should handle localhost URLs', () {
      final iriParts = _parseIriParts('http://localhost:8080/api/items/456',
          '{+baseUrl}/api/items/{itemId}', ['baseUrl', 'itemId']);

      expect(iriParts['baseUrl'], 'http://localhost:8080');
      expect(iriParts['itemId'], '456');
    });

    test('should handle file URLs', () {
      final iriParts = _parseIriParts('file:///home/user/documents/report.pdf',
          'file:///{+path}/documents/{filename}', ['path', 'filename']);

      expect(iriParts['path'], 'home/user');
      expect(iriParts['filename'], 'report.pdf');
    });
    test('should handle file URLs without extension', () {
      final iriParts = _parseIriParts('file:///home/user/documents/report.pdf',
          'file:///{+path}/documents/{filename}.pdf', ['path', 'filename']);

      expect(iriParts['path'], 'home/user');
      expect(iriParts['filename'], 'report');
    });
    test('should handle URLs without extension', () {
      final iriParts = _parseIriParts('http://example.com/report.pdf',
          '{+baseUri}/{filename}.pdf', ['baseUri', 'filename']);

      expect(iriParts['baseUri'], 'http://example.com');
      expect(iriParts['filename'], 'report');
    });

    test('should handle URNs', () {
      final iriParts = _parseIriParts('urn:isbn:0451450523',
          'urn:{type}:{identifier}', ['type', 'identifier']);

      expect(iriParts['type'], 'isbn');
      expect(iriParts['identifier'], '0451450523');
    });

    test('should handle relative paths', () {
      final iriParts = _parseIriParts('docs/api/reference',
          '{section}/{subsection}/{page}', ['section', 'subsection', 'page']);

      expect(iriParts['section'], 'docs');
      expect(iriParts['subsection'], 'api');
      expect(iriParts['page'], 'reference');
    });

    test('should handle empty segments gracefully', () {
      final iriParts = _parseIriParts('https://example.com//users/123',
          '{+baseUri}//users/{id}', ['baseUri', 'id']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['id'], '123');
    });

    test('should handle template with only literal parts (no variables)', () {
      final iriParts =
          _parseIriParts('static/path/here', 'static/path/here', []);

      expect(iriParts, isEmpty);
    });

    test('should handle variables with underscores and numbers', () {
      final iriParts = _parseIriParts(
          'https://api.example.com/v1/user_profiles/user_123',
          '{+base_url}/v1/user_profiles/{user_id}',
          ['base_url', 'user_id']);

      expect(iriParts['base_url'], 'https://api.example.com');
      expect(iriParts['user_id'], 'user_123');
    });

    test('should handle very long URIs', () {
      final longUri =
          'https://very.long.domain.name.example.com/api/v2/extremely/long/path/with/many/segments/final/resource/12345';
      final iriParts = _parseIriParts(
          longUri, '{+baseUri}/final/resource/{id}', ['baseUri', 'id']);

      expect(iriParts['baseUri'],
          'https://very.long.domain.name.example.com/api/v2/extremely/long/path/with/many/segments');
      expect(iriParts['id'], '12345');
    });

    test('should handle URI with port numbers', () {
      final iriParts = _parseIriParts(
          'https://example.com:9443/secure/api/data/789',
          '{+baseUri}/data/{dataId}',
          ['baseUri', 'dataId']);

      expect(iriParts['baseUri'], 'https://example.com:9443/secure/api');
      expect(iriParts['dataId'], '789');
    });

    test('should handle international domain names', () {
      final iriParts = _parseIriParts(
          'https://münchen.example.de/resources/item-456',
          '{+baseUri}/resources/{resourceId}',
          ['baseUri', 'resourceId']);

      expect(iriParts['baseUri'], 'https://münchen.example.de');
      expect(iriParts['resourceId'], 'item-456');
    });

    test('should handle empty variable values', () {
      final iriParts =
          _parseIriParts('api//test', 'api/{emptyVar}/test', ['emptyVar']);

      expect(iriParts['emptyVar'], '');
    });

    test('should handle variables with special regex characters', () {
      final iriParts = _parseIriParts('api/v1.2/items/item-123.json',
          'api/{version}/items/{itemFile}', ['version', 'itemFile']);

      expect(iriParts['version'], 'v1.2');
      expect(iriParts['itemFile'], 'item-123.json');
    });

    test('should handle template with encoded characters', () {
      final iriParts = _parseIriParts(
          'https://example.com/users/john%20doe/profile',
          '{+baseUri}/users/{username}/profile',
          ['baseUri', 'username']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['username'], 'john%20doe');
    });

    test('should handle malformed templates gracefully', () {
      final iriParts = _parseIriParts('https://example.com/test',
          '{unclosedVariable/test', ['unclosedVariable']);

      expect(iriParts, isEmpty);
    });

    test('should handle case where variable is not in template', () {
      final iriParts = _parseIriParts('https://example.com/test',
          'https://example.com/test', ['nonExistentVar']);

      expect(iriParts, isEmpty);
    });

    test('should handle very short URIs', () {
      final iriParts = _parseIriParts('a', '{singleChar}', ['singleChar']);

      expect(iriParts['singleChar'], 'a');
    });

    test('should handle multiple occurrences of same variable pattern', () {
      // This tests a potential edge case in replaceFirst
      final iriParts =
          _parseIriParts('prefix_test_suffix', 'prefix_{var}_suffix', ['var']);

      expect(iriParts['var'], 'test');
    });

    // Tests specifically for RFC 6570 reserved expansion functionality
    group('RFC 6570 reserved expansion tests', () {
      test('should distinguish between default and +reserved expansion', () {
        // Default behavior: baseUri should NOT include slashes
        final iriPartsDefault = _parseIriParts(
            'https://example.com/api/users/123',
            '{baseUri}/api/users/{id}',
            ['baseUri', 'id']);

        expect(iriPartsDefault['baseUri'], 'https://example.com');
        expect(iriPartsDefault['id'], '123');

        // Reserved expansion: baseUri SHOULD include slashes
        final iriPartsExpanded = _parseIriParts(
            'https://example.com/api/users/123',
            '{+baseUri}/users/{id}',
            ['baseUri', 'id']);

        expect(iriPartsExpanded['baseUri'], 'https://example.com/api');
        expect(iriPartsExpanded['id'], '123');
      });

      test('should handle mixed expansion types in same template', () {
        final iriParts = _parseIriParts(
            'https://api.example.com/v1/files/report.pdf',
            '{+baseUri}/files/{filename}.pdf',
            ['baseUri', 'filename']);

        expect(iriParts['baseUri'], 'https://api.example.com/v1');
        expect(iriParts['filename'], 'report');
      });

      test('should handle path variables with +reserved expansion', () {
        final iriParts = _parseIriParts(
            'files/documents/subfolder/project/readme.txt',
            'files/{+path}/{filename}.txt',
            ['path', 'filename']);

        expect(iriParts['path'], 'documents/subfolder/project');
        expect(iriParts['filename'], 'readme');
      });

      test('should handle consecutive variables with different expansion types',
          () {
        final iriParts = _parseIriParts(
            'https://cdn.example.com/images/user/avatar.jpg',
            '{+baseUrl}/{category}/{filename}.jpg',
            ['baseUrl', 'category', 'filename']);

        expect(iriParts['baseUrl'], 'https://cdn.example.com/images');
        expect(iriParts['category'], 'user');
        expect(iriParts['filename'], 'avatar');
      });
    });
  });
}
