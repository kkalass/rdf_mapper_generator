import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/mappers/iri_mapper.dart';

// Mock implementations for testing
class MockLibraryElement implements LibraryInfo {
  @override
  final String identifier;
  
  final List<MockElementAnnotation> _metadata = [];
  
  MockLibraryElement(this.identifier);
  
  @override
  List<dynamic> get metadata => _metadata;
}

class MockClassElement implements NamedElement {
  @override
  final String name;
  @override
  final MockLibraryElement? library;
  
  final List<MockElementAnnotation> _metadata = [];
  
  MockClassElement(this.name, {this.library});
  
  @override
  List<dynamic> get metadata => _metadata;
}

class MockFieldElement implements NamedElement {
  @override
  final String name;
  final MockDartType type;
  @override
  final MockLibraryElement? library;
  
  final List<MockElementAnnotation> _metadata = [];
  
  MockFieldElement(this.name, this.type, {this.library});
  
  @override
  List<dynamic> get metadata => _metadata;
}

class MockDartType implements TypeInfo {
  final String name;
  
  MockDartType(this.name);
  
  @override
  String getDisplayName({bool withNullability = false}) => name;
  
  @override
  String getDisplayString({bool withNullability = false}) => name;
  
  @override
  String toString() => 'MockDartType($name)';
}

class MockElementAnnotation {
  final MockDartObject? value;
  
  MockElementAnnotation({this.value});
  
  MockDartObject? computeConstantValue() => value;
}

class MockDartObject implements AnnotationValue {
  final MockDartType? _type;
  final Map<String, dynamic> fieldValues;
  
  MockDartObject({MockDartType? type, Map<String, dynamic>? fieldValues}) 
      : _type = type,
        fieldValues = fieldValues ?? {};
  
  @override
  dynamic getField(String name) => fieldValues[name];
  
  @override
  String? toStringValue() => fieldValues[name]?.toString();
  
  @override
  bool? toBoolValue() => fieldValues[name] as bool?;
  
  @override
  bool get isNull => false;
  
  @override
  TypeInfo? get type => _type;
}


// Extension to provide toString() for our mock elements
extension MockElementExtension on dynamic {
  String get name => (this as dynamic).name;
  dynamic get library => (this as dynamic).library;
  List<dynamic> get metadata => (this as dynamic).metadata ?? [];
}

void main() {
  group('IriMapper', () {
    late MockLibraryElement mockLibrary;
    
    setUp(() {
      mockLibrary = MockLibraryElement('package:test/test.dart');
    });
    
    test('should generate default IRI for class element', () {
      final element = MockClassElement('TestClass', library: mockLibrary);
      final iri = IriMapper.generateIri(element);
      expect(iri, isNotNull);
      expect(iri, contains('test/TestClass'));
    });
    
    test('should generate default IRI for field element', () {
      final field = MockFieldElement(
        'testField', 
        MockDartType('String'), 
        library: mockLibrary
      );
      final iri = IriMapper.generateIri(field);
      expect(iri, isNotNull);
      expect(iri, contains('test/testField'));
    });
    
    test('should convert Dart type to XSD type', () {
      final mockStringType = MockDartType('String');
      final mockIntType = MockDartType('int');
      final mockDoubleType = MockDartType('double');
      final mockNumType = MockDartType('num');
      final mockBoolType = MockDartType('bool');
      final mockDateTimeType = MockDartType('DateTime');
      final mockOtherType = MockDartType('SomeOtherType');
      
      expect(
        IriMapper.dartTypeToXsdType(mockStringType), 
        'http://www.w3.org/2001/XMLSchema#string'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockIntType), 
        'http://www.w3.org/2001/XMLSchema#decimal'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockDoubleType), 
        'http://www.w3.org/2001/XMLSchema#decimal'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockNumType), 
        'http://www.w3.org/2001/XMLSchema#decimal'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockBoolType), 
        'http://www.w3.org/2001/XMLSchema#boolean'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockDateTimeType), 
        'http://www.w3.org/2001/XMLSchema#dateTime'
      );
      expect(
        IriMapper.dartTypeToXsdType(mockOtherType), 
        isNull
      );
    });
    
    test('should get base IRI from package name', () {
      final library = MockLibraryElement('package:test_package/test.dart');
      final baseIri = IriMapper.getBaseIri(library);
      expect(baseIri, isNotNull);
      expect(baseIri, contains('test_package'));
    });
  });
}
