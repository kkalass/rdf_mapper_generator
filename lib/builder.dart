import 'package:build/build.dart';

Builder rdfMapperBuilder(BuilderOptions options) => RdfMapperBuilder();

class RdfMapperBuilder implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    // TODO: Implement build logic.
    try {
      // For now, do nothing.
      // In the future, this will involve:
      // 1. Reading the input source file.
      // 2. Parsing the source file to find annotations.
      // 3. Generating the mapper code.
      // 4. Writing the generated code to the output file.
      print('RdfMapperBuilder: Processing ${buildStep.inputId}');
    } catch (e, s) {
      print('RdfMapperBuilder: Error processing ${buildStep.inputId}: $e\n$s');
      // Optionally, rethrow the error or log it to a file.
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.g.dart']
      };
}
