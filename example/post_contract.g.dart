// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_contract.dart';

// **************************************************************************
// ContractGenerator
// **************************************************************************

/// Generated contract for [PostContract].
final postContract = HttpContract(
  mode: ContractMode.strict,
  version: '1.0',
  fields: {
    'id': ContractField.required(type: FieldType.number),
    'title': ContractField.required(type: FieldType.string),
    'body': ContractField.required(type: FieldType.string),
    'tags': ContractField.list(),
    'reactions': ContractField.nested(nestedContract: reactionsContract),
    'views': ContractField.required(type: FieldType.number),
    'userId': ContractField.required(type: FieldType.number),
  },
);

/// Generated contract for [ReactionsContract].
final reactionsContract = HttpContract(
  fields: {
    'likes': ContractField.required(type: FieldType.number),
    'dislikes': ContractField.required(type: FieldType.number),
  },
);
