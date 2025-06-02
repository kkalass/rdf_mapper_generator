import 'package:rdf_mapper_generator/src/processors/global_resource_processor.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  test('debug source reference resolution', () async {
    final libraryElement =
        await analyzeTestFile('global_resource_processor_test_models.dart');
    final bookClass = libraryElement.getClass2('Book')!;
    final resourceInfo = GlobalResourceProcessor.processClass(bookClass)!;

    print('classIri: ${resourceInfo.annotation.classIri}');
    print('classIriSourceRef: ${resourceInfo.annotation.classIriSourceRef}');
    print(
        'classIriSourceRef.reference: ${resourceInfo.annotation.classIriSourceRef?.reference}');
    print(
        'classIriSourceRef.importUri: ${resourceInfo.annotation.classIriSourceRef?.importUri}');
    print(
        'classIriSourceRef.iriValue: ${resourceInfo.annotation.classIriSourceRef?.iriValue}');
  });
}
