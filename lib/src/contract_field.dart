/// Represents the expected data type of a field in an HTTP contract.
enum FieldType {
  /// A string value.
  string,

  /// A numeric value (int or double).
  number,

  /// A boolean value.
  boolean,

  /// A list/array value.
  list,

  /// A map/object value.
  map,

  /// Any type — no type checking is performed.
  any,
}

/// Defines the expected shape and constraints of a single field
/// within an [HttpContract].
class ContractField {
  /// The expected data type for this field.
  final FieldType type;

  /// Whether this field must be present in the response.
  final bool isRequired;

  /// Whether this field can have a `null` value.
  final bool isNullable;

  /// For fields of type [FieldType.map], the nested contract
  /// describing the expected shape of the nested object.
  final dynamic nestedContract;

  /// For fields of type [FieldType.list], the contract describing
  /// the expected shape of each item in the list.
  final dynamic listItemContract;

  /// Whether this field is deprecated and should trigger a warning.
  final bool isDeprecated;

  /// An optional message describing why this field is deprecated.
  final String? deprecationMessage;

  /// Creates a [ContractField] with full control over all properties.
  const ContractField({
    required this.type,
    this.isRequired = true,
    this.isNullable = false,
    this.nestedContract,
    this.listItemContract,
    this.isDeprecated = false,
    this.deprecationMessage,
  });

  /// Creates a required field of the given [type].
  const ContractField.required({required this.type})
      : isRequired = true,
        isNullable = false,
        nestedContract = null,
        listItemContract = null,
        isDeprecated = false,
        deprecationMessage = null;

  /// Creates an optional field of the given [type].
  const ContractField.optional({required this.type})
      : isRequired = false,
        isNullable = false,
        nestedContract = null,
        listItemContract = null,
        isDeprecated = false,
        deprecationMessage = null;

  /// Creates a nullable field of the given [type].
  const ContractField.nullable({required this.type})
      : isRequired = true,
        isNullable = true,
        nestedContract = null,
        listItemContract = null,
        isDeprecated = false,
        deprecationMessage = null;

  /// Creates a field representing a nested object with its own [contract].
  const ContractField.nested({
    required this.nestedContract,
    this.isRequired = true,
  })  : type = FieldType.map,
        isNullable = false,
        listItemContract = null,
        isDeprecated = false,
        deprecationMessage = null;

  /// Creates a field representing a list, optionally with an [itemContract]
  /// that validates each item in the list.
  const ContractField.list({
    this.listItemContract,
    this.isRequired = true,
  })  : type = FieldType.list,
        isNullable = false,
        nestedContract = null,
        isDeprecated = false,
        deprecationMessage = null;

  /// Creates a deprecated field of the given [type] with an optional [message].
  const ContractField.deprecated({
    required this.type,
    String? message,
  })  : isRequired = false,
        isNullable = false,
        nestedContract = null,
        listItemContract = null,
        isDeprecated = true,
        deprecationMessage = message;

  /// Creates a copy of this field with the given properties overridden.
  ContractField copyWith({
    FieldType? type,
    bool? isRequired,
    bool? isNullable,
    dynamic nestedContract,
    dynamic listItemContract,
    bool? isDeprecated,
    String? deprecationMessage,
  }) {
    return ContractField(
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isNullable: isNullable ?? this.isNullable,
      nestedContract: nestedContract ?? this.nestedContract,
      listItemContract: listItemContract ?? this.listItemContract,
      isDeprecated: isDeprecated ?? this.isDeprecated,
      deprecationMessage: deprecationMessage ?? this.deprecationMessage,
    );
  }

  @override
  String toString() {
    return 'ContractField(type: $type, isRequired: $isRequired, '
        'isNullable: $isNullable, isDeprecated: $isDeprecated)';
  }
}
