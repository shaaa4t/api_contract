import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  group('ContractValidationResult', () {
    test('isValid is false when violations exist', () {
      final result = ContractValidationResult(
        violations: [
          const Violation(
            fieldPath: 'name',
            type: ViolationType.missingRequiredField,
            message: 'Required field "name" is missing',
          ),
        ],
      );

      expect(result.isValid, isFalse);
    });

    test('isValid is true when no violations', () {
      final result = ContractValidationResult(violations: []);

      expect(result.isValid, isTrue);
    });

    test('throwIfInvalid throws ContractViolationException', () {
      final result = ContractValidationResult(
        violations: [
          const Violation(
            fieldPath: 'id',
            type: ViolationType.missingRequiredField,
            message: 'Required field "id" is missing',
          ),
        ],
      );

      expect(
        () => result.throwIfInvalid(),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('throwIfInvalid does not throw when valid', () {
      final result = ContractValidationResult(violations: []);

      expect(() => result.throwIfInvalid(), returnsNormally);
    });

    test('when() routes to valid callback when no violations', () {
      final result = ContractValidationResult(violations: []);

      final output = result.when(
        valid: () => 'valid',
        invalid: (violations) => 'invalid',
      );

      expect(output, 'valid');
    });

    test('when() routes to invalid callback when violations exist', () {
      final result = ContractValidationResult(
        violations: [
          const Violation(
            fieldPath: 'field',
            type: ViolationType.typeMismatch,
            message: 'type mismatch',
          ),
        ],
      );

      final output = result.when(
        valid: () => 'valid',
        invalid: (violations) => 'invalid: ${violations.length}',
      );

      expect(output, 'invalid: 1');
    });
  });

  group('ContractViolationException', () {
    test('toString includes all violations', () {
      const exception = ContractViolationException([
        Violation(
          fieldPath: 'name',
          type: ViolationType.missingRequiredField,
          message: 'Required field "name" is missing',
        ),
        Violation(
          fieldPath: 'age',
          type: ViolationType.typeMismatch,
          message: 'Expected type "number" but got "String"',
        ),
      ]);

      final str = exception.toString();
      expect(str, contains('2 violation(s)'));
      expect(str, contains('name'));
      expect(str, contains('age'));
    });
  });

  group('Violation', () {
    test('toString includes field path and message', () {
      const violation = Violation(
        fieldPath: 'user.address.city',
        type: ViolationType.typeMismatch,
        message: 'Expected string',
      );

      expect(violation.toString(), contains('user.address.city'));
      expect(violation.toString(), contains('Expected string'));
    });
  });
}
