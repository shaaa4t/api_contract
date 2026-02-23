import 'package:api_contract_validator/src/contract.dart';

/// Central registry mapping URL path patterns to contracts.
///
/// - Use `{placeholder}` for dynamic path segments, e.g. `/users/{id}`.
/// - Keep request and response registries separate; payload shapes often differ.

/// Request-body contracts: validate `RequestOptions.data` before sending.
final Map<String, HttpContract> requestContracts = {
  // Example:
  // '/posts': HttpContract(fields: {
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
};

/// Response-body contracts: validate server responses.
final Map<String, HttpContract> responseContracts = {
  // Example for single and detail endpoints:
  // '/posts': HttpContract(fields: {
  //   'id': const ContractField.required(type: FieldType.number),
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
  // '/posts/{id}': HttpContract(fields: {
  //   'id': const ContractField.required(type: FieldType.number),
  //   'title': const ContractField.required(type: FieldType.string),
  //   'body': const ContractField.optional(type: FieldType.string),
  //   'userId': const ContractField.required(type: FieldType.number),
  // }, mode: ContractMode.strict),
};
