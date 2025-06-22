import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';

final _log = Logger('DartFormatter');

/// Utility class for formatting generated Dart code.
class DartCodeFormatter {
  static final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  /// Formats the given Dart code using dart_style.
  ///
  /// Returns the formatted code on success, or the original unformatted code
  /// if formatting fails (with appropriate logging).
  static String formatCode(String code) {
    try {
      return _formatter.format(code);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to format generated Dart code: $e',
        e,
        stackTrace,
      );
      // Return unformatted code as fallback to avoid build failures
      return code;
    }
  }
}
