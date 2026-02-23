import '../contract.dart';
import '../contract_field.dart';

/// Generates an [ApiContract] from a JSON Schema / OpenAPI / Swagger schema.
///
/// Supports the following JSON Schema keywords:
/// - `"type"`: `"string"` | `"number"` | `"integer"` | `"boolean"` | `"array"` | `"object"`
/// - `"required"`: array of required field names at object level
/// - `"properties"`: map of field names to their schemas
/// - `"nullable"`: boolean
/// - `"items"`: schema for array items
/// - `"$ref"`: basic `#/definitions/X` resolution
class FromSchemaGenerator {
  const FromSchemaGenerator._();

  /// Generates an [ApiContract] from a JSON Schema [Map].
  ///
  /// If the schema contains `"definitions"`, they are used to resolve
  /// `"$ref"` references.
  static ApiContract generate(Map<String, dynamic> schema) {
    return _parseObjectSchema(schema, schema);
  }

  static ApiContract _parseObjectSchema(
    Map<String, dynamic> schema,
    Map<String, dynamic> rootSchema,
  ) {
    final rawProperties = schema['properties'];
    final properties = rawProperties is Map
        ? Map<String, dynamic>.from(rawProperties)
        : <String, dynamic>{};
    final requiredFields =
        (schema['required'] as List<dynamic>?)?.cast<String>() ?? [];

    final fields = <String, ContractField>{};

    for (final entry in properties.entries) {
      var fieldSchema = Map<String, dynamic>.from(entry.value as Map);

      // Resolve $ref if present.
      if (fieldSchema.containsKey(r'$ref')) {
        fieldSchema = _resolveRef(
          fieldSchema[r'$ref'] as String,
          rootSchema,
        );
      }

      final isRequired = requiredFields.contains(entry.key);
      final isNullable = fieldSchema['nullable'] == true;

      fields[entry.key] = _parseField(
        fieldSchema,
        rootSchema,
        isRequired: isRequired,
        isNullable: isNullable,
      );
    }

    return ApiContract(fields: fields);
  }

  static ContractField _parseField(
    Map<String, dynamic> fieldSchema,
    Map<String, dynamic> rootSchema, {
    required bool isRequired,
    required bool isNullable,
  }) {
    // Resolve $ref if present.
    if (fieldSchema.containsKey(r'$ref')) {
      fieldSchema = _resolveRef(
        fieldSchema[r'$ref'] as String,
        rootSchema,
      );
    }

    final type = fieldSchema['type'] as String?;

    switch (type) {
      case 'string':
        return ContractField(
          type: FieldType.string,
          isRequired: isRequired,
          isNullable: isNullable,
        );
      case 'number':
      case 'integer':
        return ContractField(
          type: FieldType.number,
          isRequired: isRequired,
          isNullable: isNullable,
        );
      case 'boolean':
        return ContractField(
          type: FieldType.boolean,
          isRequired: isRequired,
          isNullable: isNullable,
        );
      case 'array':
        final rawItems = fieldSchema['items'];
        final items = rawItems is Map
            ? Map<String, dynamic>.from(rawItems)
            : null;
        dynamic itemContract;
        if (items != null) {
          var resolvedItems = items;
          if (resolvedItems.containsKey(r'$ref')) {
            resolvedItems = _resolveRef(
              resolvedItems[r'$ref'] as String,
              rootSchema,
            );
          }
          if (resolvedItems['type'] == 'object') {
            itemContract = _parseObjectSchema(resolvedItems, rootSchema);
          }
        }
        return ContractField(
          type: FieldType.list,
          isRequired: isRequired,
          isNullable: isNullable,
          listItemContract: itemContract,
        );
      case 'object':
        final nestedContract = _parseObjectSchema(fieldSchema, rootSchema);
        return ContractField(
          type: FieldType.map,
          isRequired: isRequired,
          isNullable: isNullable,
          nestedContract: nestedContract,
        );
      default:
        return ContractField(
          type: FieldType.any,
          isRequired: isRequired,
          isNullable: isNullable,
        );
    }
  }

  /// Resolves a `$ref` string like `"#/definitions/Address"` from the
  /// root schema.
  static Map<String, dynamic> _resolveRef(
    String ref,
    Map<String, dynamic> rootSchema,
  ) {
    // Support "#/definitions/X" and "#/components/schemas/X" formats.
    final parts = ref.split('/');
    dynamic current = rootSchema;

    // Skip the leading "#".
    for (var i = 1; i < parts.length; i++) {
      if (current is Map<String, dynamic>) {
        current = current[parts[i]];
      } else {
        throw FormatException('Cannot resolve \$ref "$ref"');
      }
    }

    if (current is Map<String, dynamic>) {
      return current;
    }

    throw FormatException('Resolved \$ref "$ref" is not an object schema');
  }
}
