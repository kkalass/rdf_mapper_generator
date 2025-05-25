/// Contains information about a class annotated with @RdfGlobalResource
class GlobalResourceInfo {
  /// The name of the class
  final String className;
  
  /// The IRI that identifies the RDF type
  final String typeIri;
  
  /// Whether this resource should be registered globally
  final bool registerGlobally;
  
  /// List of constructors in the class
  final List<ConstructorInfo> constructors;
  
  /// List of fields in the class
  final List<FieldInfo> fields;

  const GlobalResourceInfo({
    required this.className,
    required this.typeIri,
    required this.registerGlobally,
    required this.constructors,
    required this.fields,
  });

  @override
  String toString() {
    return 'GlobalResourceInfo{\n'
        '  className: $className,\n'
        '  typeIri: $typeIri,\n'
        '  registerGlobally: $registerGlobally,\n'
        '  constructors: $constructors,\n'
        '  fields: $fields\n'
        '}';
  }
}

/// Information about a constructor
class ConstructorInfo {
  /// The name of the constructor (empty string for default constructor)
  final String name;
  
  /// Whether this is a factory constructor
  final bool isFactory;
  
  /// Whether this is a const constructor
  final bool isConst;
  
  /// Whether this is the default constructor
  final bool isDefaultConstructor;
  
  /// List of parameters for this constructor
  final List<ParameterInfo> parameters;

  const ConstructorInfo({
    required this.name,
    required this.isFactory,
    required this.isConst,
    required this.isDefaultConstructor,
    required this.parameters,
  });

  @override
  String toString() {
    return 'ConstructorInfo{\n'
        '  name: $name,\n'
        '  isFactory: $isFactory,\n'
        '  isConst: $isConst,\n'
        '  isDefaultConstructor: $isDefaultConstructor,\n'
        '  parameters: $parameters\n'
        '}';
  }
}

/// Information about a parameter
class ParameterInfo {
  /// The name of the parameter
  final String name;
  
  /// The type of the parameter as a string
  final String type;
  
  /// Whether this parameter is required
  final bool isRequired;
  
  /// Whether this is a named parameter
  final bool isNamed;
  
  /// Whether this is a positional parameter
  final bool isPositional;
  
  /// Whether this parameter is optional
  final bool isOptional;

  const ParameterInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.isPositional,
    required this.isOptional,
  });

  @override
  String toString() {
    return 'ParameterInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isRequired: $isRequired,\n'
        '  isNamed: $isNamed,\n'
        '  isPositional: $isPositional,\n'
        '  isOptional: $isOptional\n'
        '}';
  }
}

/// Information about a field
class FieldInfo {
  /// The name of the field
  final String name;
  
  /// The type of the field as a string
  final String type;
  
  /// Whether this field is final
  final bool isFinal;
  
  /// Whether this field is late-initialized
  final bool isLate;
  
  /// Whether this is a static field
  final bool isStatic;
  
  /// Whether this is a synthetic field
  final bool isSynthetic;

  const FieldInfo({
    required this.name,
    required this.type,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
  });

  @override
  String toString() {
    return 'FieldInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic\n'
        '}';
  }
}
