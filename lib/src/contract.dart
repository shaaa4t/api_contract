import 'contract_field.dart';
import 'generators/from_json_generator.dart';
import 'generators/from_schema_generator.dart';
import 'validator.dart';
import 'violation.dart';

/// Defines whether unexpected fields in the response trigger violations.
enum ContractMode {
  /// Extra fields not defined in the contract cause violations.
  strict,

  /// Extra fields are silently ignored.
  lenient,
}

/// Defines the expected shape of an API JSON response.
///
/// An [ApiContract] is a collection of named [ContractField]s that
/// describe what fields are expected, their types, whether they're
/// required, and any nested structure.
///
/// ```dart
/// final contract = ApiContract(
///   fields: {
///     'id': ContractField.required(type: FieldType.string),
///     'name': ContractField.required(type: FieldType.string),
///   },
/// );
///
/// final result = contract.validate(responseJson);
/// ```
class ApiContract {
  /// The expected fields in the response.
  final Map<String, ContractField> fields;

  /// The validation mode — [ContractMode.strict] flags unexpected fields,
  /// [ContractMode.lenient] ignores them.
  final ContractMode mode;

  /// An optional version string for this contract, useful for tracking
  /// contract evolution over time.
  final String? version;

  /// Creates an [ApiContract] with the given [fields], [mode], and [version].
  const ApiContract({
    required this.fields,
    this.mode = ContractMode.lenient,
    this.version,
  });

  /// Auto-generates a contract from a sample JSON response.
  ///
  /// All fields default to required. Adjust individual fields afterward
  /// as needed.
  ///
  /// ```dart
  /// final contract = ApiContract.fromJson({
  ///   "id": "123",
  ///   "name": "Ahmed",
  /// });
  /// ```
  static ApiContract fromJson(Map<String, dynamic> sampleJson) {
    return FromJsonGenerator.generate(sampleJson);
  }

  /// Generates a contract from a JSON Schema / OpenAPI / Swagger schema.
  ///
  /// Supports `"type"`, `"required"`, `"properties"`, `"nullable"`,
  /// `"items"`, and basic `"$ref"` resolution.
  ///
  /// ```dart
  /// final contract = ApiContract.fromJsonSchema({
  ///   "type": "object",
  ///   "required": ["id"],
  ///   "properties": {
  ///     "id": {"type": "string"},
  ///   },
  /// });
  /// ```
  static ApiContract fromJsonSchema(Map<String, dynamic> schema) {
    return FromSchemaGenerator.generate(schema);
  }

  /// Validates a JSON [Map] against this contract.
  ///
  /// Returns a [ContractValidationResult] containing any violations found.
  ContractValidationResult validate(Map<String, dynamic> json) {
    final violations = Validator.validate(this, json);
    return ContractValidationResult(
      violations: violations,
      contractVersion: version,
    );
  }

  // Note: direct http.Response validation was removed to keep the
  // package focused on Dio usage via interceptors.

  /// Creates a new contract version by adding or removing fields.
  ///
  /// - [version]: The new version string.
  /// - [added]: New fields to add to the contract.
  /// - [removed]: Field names to remove from the contract.
  ApiContract upgrade({
    required String version,
    Map<String, ContractField>? added,
    List<String>? removed,
  }) {
    final newFields = Map<String, ContractField>.from(fields);

    if (removed != null) {
      for (final key in removed) {
        newFields.remove(key);
      }
    }

    if (added != null) {
      newFields.addAll(added);
    }

    return ApiContract(
      fields: newFields,
      mode: mode,
      version: version,
    );
  }

  /// Creates a copy of this contract with the given properties overridden.
  ApiContract copyWith({
    Map<String, ContractField>? fields,
    ContractMode? mode,
    String? version,
  }) {
    return ApiContract(
      fields: fields ?? this.fields,
      mode: mode ?? this.mode,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'ApiContract(fields: ${fields.length}, '
        'mode: ${mode.name}, version: $version)';
  }
}
