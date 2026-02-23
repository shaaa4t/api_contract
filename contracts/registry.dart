import 'package:api_contract/src/contract.dart';

/// Central registry mapping URL path patterns to contracts.
///
/// - Use `{placeholder}` for dynamic path segments, e.g. `/users/{id}`.
/// - Keep request and response registries separate; payload shapes often differ.

/// Request-body contracts: validate `RequestOptions.data` before sending.
final Map<String, ApiContract> requestContracts = {
  // Example:
  // '/posts': ApiContract(fields: {
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
};

/// Response-body contracts: validate server responses.
final Map<String, ApiContract> responseContracts = {
  // Example for single and detail endpoints:
  // '/posts': ApiContract(fields: {
  //   'id': const ContractField.required(type: FieldType.number),
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
  // '/posts/{id}': ApiContract(fields: {
  //   'id': const ContractField.required(type: FieldType.number),
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
};
