import 'package:api_contract_validator/api_contract_validator.dart';
import 'package:test/test.dart';

void main() {
  group('HttpContract.validate', () {
    test('passes when all required fields present with correct types', () {
      final contract = HttpContract(
        fields: {
          'id': const ContractField.required(type: FieldType.string),
          'name': const ContractField.required(type: FieldType.string),
          'age': const ContractField.required(type: FieldType.number),
        },
      );

      final result = contract.validate({
        'id': '123',
        'name': 'Ahmed',
        'age': 25,
      });

      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);
    });

    test('fails when required field is missing', () {
      final contract = HttpContract(
        fields: {
          'id': const ContractField.required(type: FieldType.string),
          'name': const ContractField.required(type: FieldType.string),
        },
      );

      final result = contract.validate({'id': '123'});

      expect(result.isValid, isFalse);
      expect(result.violations, hasLength(1));
      expect(
        result.violations.first.type,
        ViolationType.missingRequiredField,
      );
      expect(result.violations.first.fieldPath, 'name');
    });

    test('fails on type mismatch', () {
      final contract = HttpContract(
        fields: {
          'age': const ContractField.required(type: FieldType.number),
        },
      );

      final result = contract.validate({'age': 'not a number'});

      expect(result.isValid, isFalse);
      expect(result.violations.first.type, ViolationType.typeMismatch);
    });

    test('passes with missing optional field', () {
      final contract = HttpContract(
        fields: {
          'id': const ContractField.required(type: FieldType.string),
          'nickname': const ContractField.optional(type: FieldType.string),
        },
      );

      final result = contract.validate({'id': '123'});

      expect(result.isValid, isTrue);
    });

    test('strict mode fails on extra fields', () {
      final contract = HttpContract(
        mode: ContractMode.strict,
        fields: {
          'id': const ContractField.required(type: FieldType.string),
        },
      );

      final result = contract.validate({
        'id': '123',
        'unexpected': 'value',
      });

      expect(result.isValid, isFalse);
      expect(
        result.violations.first.type,
        ViolationType.unexpectedField,
      );
    });

    test('lenient mode passes on extra fields', () {
      final contract = HttpContract(
        mode: ContractMode.lenient,
        fields: {
          'id': const ContractField.required(type: FieldType.string),
        },
      );

      final result = contract.validate({
        'id': '123',
        'extra': 'value',
      });

      expect(result.isValid, isTrue);
    });
  });

  group('HttpContract.upgrade', () {
    test('adds and removes fields correctly', () {
      final v1 = HttpContract(
        version: '1.0',
        fields: {
          'id': const ContractField.required(type: FieldType.string),
          'name': const ContractField.required(type: FieldType.string),
          'age': const ContractField.optional(type: FieldType.number),
        },
      );

      final v2 = v1.upgrade(
        version: '2.0',
        added: {
          'avatar': const ContractField.optional(type: FieldType.string),
        },
        removed: ['age'],
      );

      expect(v2.version, '2.0');
      expect(v2.fields.containsKey('avatar'), isTrue);
      expect(v2.fields.containsKey('age'), isFalse);
      expect(v2.fields.containsKey('id'), isTrue);
      expect(v2.fields.containsKey('name'), isTrue);
    });
  });

  group('HttpContract.fromJson', () {
    test('generates correct contract from sample JSON', () {
      final contract = HttpContract.fromJson({
        'id': '123',
        'age': 25,
        'active': true,
        'address': {'city': 'Riyadh'},
        'tags': ['flutter'],
      });

      expect(contract.fields['id']!.type, FieldType.string);
      expect(contract.fields['id']!.isRequired, isTrue);
      expect(contract.fields['age']!.type, FieldType.number);
      expect(contract.fields['active']!.type, FieldType.boolean);
      expect(contract.fields['address']!.type, FieldType.map);
      expect(contract.fields['address']!.nestedContract, isNotNull);
      expect(contract.fields['tags']!.type, FieldType.list);
    });
  });

  group('HttpContract.fromJsonSchema', () {
    test('generates correct contract with required array', () {
      final contract = HttpContract.fromJsonSchema({
        'type': 'object',
        'required': ['id', 'name'],
        'properties': {
          'id': {'type': 'string'},
          'name': {'type': 'string'},
          'age': {'type': 'number'},
        },
      });

      expect(contract.fields['id']!.isRequired, isTrue);
      expect(contract.fields['name']!.isRequired, isTrue);
      expect(contract.fields['age']!.isRequired, isFalse);
      expect(contract.fields['id']!.type, FieldType.string);
      expect(contract.fields['age']!.type, FieldType.number);
    });
  });
}
