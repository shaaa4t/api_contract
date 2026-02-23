import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  group('ApiContract.fromJsonSchema', () {
    test('required array marks correct fields as required', () {
      final contract = ApiContract.fromJsonSchema({
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
    });

    test('nullable:true marks field as nullable', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'properties': {
          'middle_name': {'type': 'string', 'nullable': true},
        },
      });

      expect(contract.fields['middle_name']!.isNullable, isTrue);
    });

    test('maps type keywords to correct FieldTypes', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'number'},
          'count': {'type': 'integer'},
          'active': {'type': 'boolean'},
          'tags': {'type': 'array'},
          'meta': {'type': 'object', 'properties': {}},
        },
      });

      expect(contract.fields['name']!.type, FieldType.string);
      expect(contract.fields['age']!.type, FieldType.number);
      expect(contract.fields['count']!.type, FieldType.number);
      expect(contract.fields['active']!.type, FieldType.boolean);
      expect(contract.fields['tags']!.type, FieldType.list);
      expect(contract.fields['meta']!.type, FieldType.map);
    });

    test('nested object schema recurses correctly', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'required': ['address'],
        'properties': {
          'address': {
            'type': 'object',
            'required': ['city'],
            'properties': {
              'city': {'type': 'string'},
              'zip': {'type': 'string'},
            },
          },
        },
      });

      expect(contract.fields['address']!.type, FieldType.map);
      final nested = contract.fields['address']!.nestedContract as ApiContract;
      expect(nested.fields['city']!.isRequired, isTrue);
      expect(nested.fields['zip']!.isRequired, isFalse);
    });

    test('array with items schema creates list with itemContract', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'properties': {
          'users': {
            'type': 'array',
            'items': {
              'type': 'object',
              'required': ['id'],
              'properties': {
                'id': {'type': 'string'},
                'name': {'type': 'string'},
              },
            },
          },
        },
      });

      final usersField = contract.fields['users']!;
      expect(usersField.type, FieldType.list);
      expect(usersField.listItemContract, isNotNull);

      final itemContract = usersField.listItemContract as ApiContract;
      expect(itemContract.fields['id']!.isRequired, isTrue);
      expect(itemContract.fields['name']!.isRequired, isFalse);
    });

    test(r'$ref resolves from definitions', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'required': ['address'],
        'properties': {
          'address': {r'$ref': '#/definitions/Address'},
        },
        'definitions': {
          'Address': {
            'type': 'object',
            'required': ['city'],
            'properties': {
              'city': {'type': 'string'},
              'zip': {'type': 'string'},
            },
          },
        },
      });

      expect(contract.fields['address']!.type, FieldType.map);
      final nested = contract.fields['address']!.nestedContract as ApiContract;
      expect(nested.fields['city']!.isRequired, isTrue);
      expect(nested.fields['zip']!.isRequired, isFalse);
    });

    test(r'$ref in array items resolves correctly', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'properties': {
          'users': {
            'type': 'array',
            'items': {r'$ref': '#/definitions/User'},
          },
        },
        'definitions': {
          'User': {
            'type': 'object',
            'required': ['id'],
            'properties': {
              'id': {'type': 'string'},
              'name': {'type': 'string'},
            },
          },
        },
      });

      final usersField = contract.fields['users']!;
      expect(usersField.listItemContract, isNotNull);

      final itemContract = usersField.listItemContract as ApiContract;
      expect(itemContract.fields['id']!.isRequired, isTrue);
    });

    test('empty properties generates empty fields', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
        'properties': <String, dynamic>{},
      });

      expect(contract.fields, isEmpty);
    });

    test('missing properties key generates empty fields', () {
      final contract = ApiContract.fromJsonSchema({
        'type': 'object',
      });

      expect(contract.fields, isEmpty);
    });
  });
}
