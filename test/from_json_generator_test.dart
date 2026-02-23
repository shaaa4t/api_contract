import 'package:api_contract_validator/api_contract_validator.dart';
import 'package:test/test.dart';

void main() {
  group('HttpContract.fromJson', () {
    test('string value creates required string field', () {
      final contract = HttpContract.fromJson({'name': 'Ahmed'});

      expect(contract.fields['name']!.type, FieldType.string);
      expect(contract.fields['name']!.isRequired, isTrue);
    });

    test('int value creates required number field', () {
      final contract = HttpContract.fromJson({'age': 25});

      expect(contract.fields['age']!.type, FieldType.number);
      expect(contract.fields['age']!.isRequired, isTrue);
    });

    test('double value creates required number field', () {
      final contract = HttpContract.fromJson({'score': 9.5});

      expect(contract.fields['score']!.type, FieldType.number);
      expect(contract.fields['score']!.isRequired, isTrue);
    });

    test('bool value creates required boolean field', () {
      final contract = HttpContract.fromJson({'active': true});

      expect(contract.fields['active']!.type, FieldType.boolean);
      expect(contract.fields['active']!.isRequired, isTrue);
    });

    test('null value creates nullable any field', () {
      final contract = HttpContract.fromJson({'unknown': null});

      expect(contract.fields['unknown']!.type, FieldType.any);
      expect(contract.fields['unknown']!.isNullable, isTrue);
    });

    test('nested map creates nested contract', () {
      final contract = HttpContract.fromJson({
        'address': {'city': 'Riyadh', 'zip': '12345'},
      });

      final addressField = contract.fields['address']!;
      expect(addressField.type, FieldType.map);
      expect(addressField.nestedContract, isNotNull);

      final nested = addressField.nestedContract as HttpContract;
      expect(nested.fields['city']!.type, FieldType.string);
      expect(nested.fields['zip']!.type, FieldType.string);
    });

    test('list of maps creates list with itemContract', () {
      final contract = HttpContract.fromJson({
        'users': [
          {'id': '1', 'name': 'Ahmed'},
        ],
      });

      final usersField = contract.fields['users']!;
      expect(usersField.type, FieldType.list);
      expect(usersField.listItemContract, isNotNull);

      final itemContract = usersField.listItemContract as HttpContract;
      expect(itemContract.fields['id']!.type, FieldType.string);
      expect(itemContract.fields['name']!.type, FieldType.string);
    });

    test('list of strings creates plain list field', () {
      final contract = HttpContract.fromJson({
        'tags': ['flutter', 'dart'],
      });

      final tagsField = contract.fields['tags']!;
      expect(tagsField.type, FieldType.list);
      expect(tagsField.listItemContract, isNull);
    });

    test('empty list creates plain list field', () {
      final contract = HttpContract.fromJson({
        'items': <dynamic>[],
      });

      final itemsField = contract.fields['items']!;
      expect(itemsField.type, FieldType.list);
      expect(itemsField.listItemContract, isNull);
    });

    test('complex nested JSON generates correct contract', () {
      final contract = HttpContract.fromJson({
        'id': '123',
        'name': 'Ahmed',
        'age': 25,
        'email': 'ahmed@test.com',
        'address': {'city': 'Riyadh', 'zip': '12345'},
        'tags': ['flutter', 'dart'],
        'posts': [
          {
            'title': 'Hello',
            'likes': 10,
          },
        ],
      });

      expect(contract.fields.length, 7);
      expect(contract.fields['id']!.type, FieldType.string);
      expect(contract.fields['age']!.type, FieldType.number);
      expect(contract.fields['address']!.nestedContract, isNotNull);
      expect(contract.fields['tags']!.listItemContract, isNull);
      expect(contract.fields['posts']!.listItemContract, isNotNull);
    });
  });
}
