import 'contract.dart';
import 'contract_field.dart';
import 'violation.dart';

/// Internal validation engine that checks JSON data against an [ApiContract].
///
/// This class contains all validation logic including type checking,
/// nested object recursion, list item validation, and strict mode
/// unexpected field detection.
class Validator {
  const Validator._();

  /// Validates [json] against [contract] and returns all violations found.
  static List<Violation> validate(
    ApiContract contract,
    Map<String, dynamic> json, {
    String prefix = '',
  }) {
    final violations = <Violation>[];

    // Check for missing required fields and validate present fields.
    for (final entry in contract.fields.entries) {
      final fieldName = entry.key;
      final field = entry.value;
      final path = prefix.isEmpty ? fieldName : '$prefix.$fieldName';

      if (!json.containsKey(fieldName)) {
        if (field.isRequired) {
          violations.add(Violation(
            fieldPath: path,
            type: ViolationType.missingRequiredField,
            message: 'Required field "$fieldName" is missing',
            expectedValue: field.type.name,
            actualValue: null,
          ));
        }
        continue;
      }

      final value = json[fieldName];

      // Check deprecated field usage.
      if (field.isDeprecated) {
        violations.add(Violation(
          fieldPath: path,
          type: ViolationType.deprecatedFieldUsed,
          message: field.deprecationMessage ??
              'Field "$fieldName" is deprecated',
          expectedValue: 'not present (deprecated)',
          actualValue: value,
        ));
      }

      // Check null value.
      if (value == null) {
        if (!field.isNullable) {
          violations.add(Violation(
            fieldPath: path,
            type: ViolationType.nullableViolation,
            message:
                'Field "$fieldName" is null but not marked as nullable',
            expectedValue: 'non-null ${field.type.name}',
            actualValue: null,
          ));
        }
        continue;
      }

      // Check type.
      if (field.type != FieldType.any) {
        if (!_typeMatches(field.type, value)) {
          violations.add(Violation(
            fieldPath: path,
            type: ViolationType.typeMismatch,
            message: 'Expected type "${field.type.name}" '
                'but got "${_dartType(value)}"',
            expectedValue: field.type.name,
            actualValue: _dartType(value),
          ));
          continue;
        }
      }

      // Recurse into nested objects.
      if (field.nestedContract != null && value is Map<String, dynamic>) {
        final nestedViolations = validate(
          field.nestedContract as ApiContract,
          value,
          prefix: path,
        );
        violations.addAll(nestedViolations);
      }

      // Validate list items.
      if (field.type == FieldType.list &&
          field.listItemContract != null &&
          value is List) {
        final itemContract = field.listItemContract as ApiContract;
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map<String, dynamic>) {
            final itemViolations = validate(
              itemContract,
              item,
              prefix: '$path[$i]',
            );
            violations.addAll(itemViolations);
          } else {
            violations.add(Violation(
              fieldPath: '$path[$i]',
              type: ViolationType.invalidListItem,
              message: 'Expected list item to be an object '
                  'but got "${_dartType(item)}"',
              expectedValue: 'Map<String, dynamic>',
              actualValue: _dartType(item),
            ));
          }
        }
      }
    }

    // Strict mode: check for unexpected fields.
    if (contract.mode == ContractMode.strict) {
      for (final key in json.keys) {
        if (!contract.fields.containsKey(key)) {
          final path = prefix.isEmpty ? key : '$prefix.$key';
          violations.add(Violation(
            fieldPath: path,
            type: ViolationType.unexpectedField,
            message: 'Unexpected field "$key" in strict mode',
            expectedValue: 'field not present',
            actualValue: json[key],
          ));
        }
      }
    }

    return violations;
  }

  /// Returns `true` if [value] matches the expected [type].
  ///
  /// Both `int` and `double` are treated as [FieldType.number].
  static bool _typeMatches(FieldType type, dynamic value) {
    switch (type) {
      case FieldType.string:
        return value is String;
      case FieldType.number:
        return value is num;
      case FieldType.boolean:
        return value is bool;
      case FieldType.list:
        return value is List;
      case FieldType.map:
        return value is Map;
      case FieldType.any:
        return true;
    }
  }

  /// Returns a human-readable type name for [value].
  static String _dartType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List';
    if (value is Map) return 'Map';
    if (value == null) return 'null';
    return value.runtimeType.toString();
  }
}
