import 'package:api_contract_validator/api_contract_validator.dart';
import 'package:test/test.dart';

void main() {
  group('Validator - nested objects', () {
    test('nested object validates recursively', () {
      final contract = HttpContract(
        fields: {
          'user': ContractField.nested(
            nestedContract: HttpContract(
              fields: {
                'name':
                    const ContractField.required(type: FieldType.string),
                'address': ContractField.nested(
                  nestedContract: HttpContract(
                    fields: {
                      'city': const ContractField.required(
                          type: FieldType.string),
                    },
                  ),
                ),
              },
            ),
          ),
        },
      );

      final result = contract.validate({
        'user': {
          'name': 'Ahmed',
          'address': {'city': 123},
        },
      });

      expect(result.isValid, isFalse);
      expect(result.violations, hasLength(1));
      expect(result.violations.first.type, ViolationType.typeMismatch);
      expect(result.violations.first.fieldPath, 'user.address.city');
    });
  });

  group('Validator - list items', () {
    test('list items validate with itemContract', () {
      final contract = HttpContract(
        fields: {
          'users': ContractField.list(
            listItemContract: HttpContract(
              fields: {
                'id':
                    const ContractField.required(type: FieldType.string),
                'name':
                    const ContractField.required(type: FieldType.string),
              },
            ),
          ),
        },
      );

      final result = contract.validate({
        'users': [
          {'id': '1', 'name': 'Ahmed'},
          {'id': '2'},
        ],
      });

      expect(result.isValid, isFalse);
      expect(result.violations, hasLength(1));
      expect(result.violations.first.fieldPath, 'users[1].name');
    });
  });

  group('Validator - dot notation paths', () {
    test('dot notation path is correct for deep violations', () {
      final contract = HttpContract(
        fields: {
          'data': ContractField.nested(
            nestedContract: HttpContract(
              fields: {
                'items': ContractField.list(
                  listItemContract: HttpContract(
                    fields: {
                      'details': ContractField.nested(
                        nestedContract: HttpContract(
                          fields: {
                            'value': const ContractField.required(
                                type: FieldType.number),
                          },
                        ),
                      ),
                    },
                  ),
                ),
              },
            ),
          ),
        },
      );

      final result = contract.validate({
        'data': {
          'items': [
            {
              'details': {'value': 'not a number'},
            },
          ],
        },
      });

      expect(result.isValid, isFalse);
      expect(
        result.violations.first.fieldPath,
        'data.items[0].details.value',
      );
    });
  });

  group('Validator - deprecated fields', () {
    test('deprecated field triggers violation', () {
      final contract = HttpContract(
        fields: {
          'oldField': const ContractField.deprecated(
            type: FieldType.string,
            message: 'Use newField instead',
          ),
        },
      );

      final result = contract.validate({'oldField': 'value'});

      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.type,
        ViolationType.deprecatedFieldUsed,
      );
      expect(
        result.violations.first.message,
        'Use newField instead',
      );
    });
  });

  group('Validator - number type handling', () {
    test('int passes as number type', () {
      final contract = HttpContract(
        fields: {
          'value': const ContractField.required(type: FieldType.number),
        },
      );

      final result = contract.validate({'value': 42});
      expect(result.isValid, isTrue);
    });

    test('double passes as number type', () {
      final contract = HttpContract(
        fields: {
          'value': const ContractField.required(type: FieldType.number),
        },
      );

      final result = contract.validate({'value': 3.14});
      expect(result.isValid, isTrue);
    });
  });

  group('Validator - nullable fields', () {
    test('nullable field accepts null value', () {
      final contract = HttpContract(
        fields: {
          'middle_name':
              const ContractField.nullable(type: FieldType.string),
        },
      );

      final result = contract.validate({'middle_name': null});
      expect(result.isValid, isTrue);
    });

    test('non-nullable field rejects null value', () {
      final contract = HttpContract(
        fields: {
          'name': const ContractField.required(type: FieldType.string),
        },
      );

      final result = contract.validate({'name': null});
      expect(result.isValid, isFalse);
      expect(
        result.violations.first.type,
        ViolationType.nullableViolation,
      );
    });
  });
}
