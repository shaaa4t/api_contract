import '../contract.dart';
import '../contract_field.dart';

/// Generates an [HttpContract] from a sample JSON response [Map].
///
/// All fields are marked as required by default. The developer can
/// then adjust individual fields to be optional or nullable as needed.
///
/// Type inference rules:
/// - `String` -> [FieldType.string], required
/// - `int` or `double` -> [FieldType.number], required
/// - `bool` -> [FieldType.boolean], required
/// - `Map` -> [FieldType.map], recurse to create nested [HttpContract]
/// - `List` -> [FieldType.list], if items are Maps, recurse for item contract
/// - `null` -> [FieldType.any], nullable
class FromJsonGenerator {
  const FromJsonGenerator._();

  /// Generates an [HttpContract] from a sample JSON [Map].
  static HttpContract generate(Map<String, dynamic> sampleJson) {
    final fields = <String, ContractField>{};

    for (final entry in sampleJson.entries) {
      fields[entry.key] = _inferField(entry.value);
    }

    return HttpContract(fields: fields);
  }

  static ContractField _inferField(dynamic value) {
    if (value == null) {
      return const ContractField(
        type: FieldType.any,
        isNullable: true,
      );
    }

    if (value is String) {
      return const ContractField.required(type: FieldType.string);
    }

    if (value is num) {
      return const ContractField.required(type: FieldType.number);
    }

    if (value is bool) {
      return const ContractField.required(type: FieldType.boolean);
    }

    if (value is Map<String, dynamic>) {
      final nestedContract = generate(value);
      return ContractField.nested(nestedContract: nestedContract);
    }

    if (value is Map) {
      final castMap = Map<String, dynamic>.from(value);
      final nestedContract = generate(castMap);
      return ContractField.nested(nestedContract: nestedContract);
    }

    if (value is List) {
      if (value.isNotEmpty && value.first is Map) {
        final firstItem = Map<String, dynamic>.from(value.first as Map);
        final itemContract = generate(firstItem);
        return ContractField.list(listItemContract: itemContract);
      }
      return const ContractField.list();
    }

    return const ContractField.required(type: FieldType.any);
  }
}
