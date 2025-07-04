import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/v7_4/analyzer_wrapper_service_v7_4.dart';

class AnalyzerWrapperServiceFactory {
  static AnalyzerWrapperService create() {
    return AnalyzerWrapperServiceV7();
  }
}
