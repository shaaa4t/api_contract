/// The type of contract violation detected during validation.
enum ViolationType {
  /// A required field is missing from the response.
  missingRequiredField,

  /// A field has a different type than expected.
  typeMismatch,

  /// An unexpected field is present (strict mode only).
  unexpectedField,

  /// A non-nullable field has a null value.
  nullableViolation,

  /// A deprecated field is present in the response.
  deprecatedFieldUsed,

  /// A list item does not match the expected item contract.
  invalidListItem,

  /// A nested object does not match the expected nested contract.
  invalidNestedObject,
}

/// Represents a single contract violation found during validation.
///
/// Each violation includes the field path in dot notation (e.g.
/// `"user.address.city"`), the type of violation, and a human-readable
/// message.
class Violation {
  /// The dot-notation path to the field that caused the violation.
  ///
  /// Example: `"user.address.city"` for a deeply nested field.
  final String fieldPath;

  /// The type of violation detected.
  final ViolationType type;

  /// A human-readable description of the violation.
  final String message;

  /// The expected value or type for this field.
  final dynamic expectedValue;

  /// The actual value or type found in the response.
  final dynamic actualValue;

  /// Creates a new [Violation].
  const Violation({
    required this.fieldPath,
    required this.type,
    required this.message,
    this.expectedValue,
    this.actualValue,
  });

  @override
  String toString() {
    return 'Violation($fieldPath: $message)';
  }
}

/// Exception thrown when contract validation fails and throwing is enabled.
class ContractViolationException implements Exception {
  /// The list of violations that caused this exception.
  final List<Violation> violations;

  /// Creates a [ContractViolationException] with the given [violations].
  const ContractViolationException(this.violations);

  @override
  String toString() {
    final buffer = StringBuffer('ContractViolationException: '
        '${violations.length} violation(s) found\n');
    for (final v in violations) {
      buffer.writeln('  - [${v.type.name}] ${v.fieldPath}: ${v.message}');
    }
    return buffer.toString();
  }
}

/// The result of validating a JSON response against an [ApiContract].
class ContractValidationResult {
  /// Whether the validation passed with no violations.
  bool get isValid => violations.isEmpty;

  /// The list of violations found during validation.
  final List<Violation> violations;

  /// The timestamp when this validation was performed.
  final DateTime checkedAt;

  /// The version of the contract used for validation, if set.
  final String? contractVersion;

  /// Creates a new [ContractValidationResult].
  ContractValidationResult({
    required this.violations,
    DateTime? checkedAt,
    this.contractVersion,
  }) : checkedAt = checkedAt ?? DateTime.now();

  /// Pattern-matches on the result, calling [valid] if there are no
  /// violations, or [invalid] with the list of violations otherwise.
  T when<T>({
    required T Function() valid,
    required T Function(List<Violation> violations) invalid,
  }) {
    if (isValid) {
      return valid();
    } else {
      return invalid(violations);
    }
  }

  /// Throws a [ContractViolationException] if the result is invalid.
  void throwIfInvalid() {
    if (!isValid) {
      throw ContractViolationException(violations);
    }
  }

  @override
  String toString() {
    if (isValid) {
      return 'ContractValidationResult(valid)';
    }
    return 'ContractValidationResult(invalid, '
        '${violations.length} violation(s))';
  }
}
