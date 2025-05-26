import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late LibraryElement2 libraryElement;

  setUpAll(() async {
    libraryElement =
        await analyzeTestFile('propert_processor_test_models.dart');
  });
}
