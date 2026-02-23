[![pub package](https://img.shields.io/pub/v/api_contract_validator.svg)](https://pub.dev/packages/api_contract_validator)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/dart-%3E%3D3.0-blue.svg)](https://dart.dev)

# api_contract_validator

A runtime API response contract validator for Flutter/Dart.
Detect mismatches between your expected API contracts and actual server responses **before** they silently break your app.

## The Problem

Backend APIs change. Fields get renamed, types shift from `int` to `String`, optional fields become null, and new fields appear without warning. Your app keeps running — but with wrong data, broken UI, or silent failures.

`api_contract_validator` catches these mismatches at runtime by validating API responses against a contract you define.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  api_contract_validator: ^0.2.0
```

For annotation-based code generation (optional):

```yaml
dependencies:
  api_contract_validator_generator: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
```

## Quick Start

### Option 1: Manual Contract Definition

```dart
import 'package:api_contract_validator/api_contract_validator.dart';

final userContract = HttpContract(
  mode: ContractMode.strict,
  version: '1.0',
  fields: {
    'id':    ContractField.required(type: FieldType.string),
    'name':  ContractField.required(type: FieldType.string),
    'age':   ContractField.optional(type: FieldType.number),
    'email': ContractField.required(type: FieldType.string),
    'address': ContractField.nested(
      nestedContract: HttpContract(fields: {
        'city': ContractField.required(type: FieldType.string),
        'zip':  ContractField.optional(type: FieldType.string),
      }),
    ),
    'tags': ContractField.list(),
  },
);
```

### Option 2: Auto-generate from JSON Sample

```dart
final userContract = HttpContract.fromJson({
  "id": "123",
  "name": "Ahmed",
  "age": 25,
  "email": "ahmed@test.com",
  "address": {"city": "Riyadh", "zip": "12345"},
  "tags": ["flutter", "dart"]
});
```

### Option 3: Generate from JSON Schema

```dart
final userContract = HttpContract.fromJsonSchema({
  "type": "object",
  "required": ["id", "name", "email"],
  "properties": {
    "id":    {"type": "string"},
    "name":  {"type": "string"},
    "age":   {"type": "number"},
    "email": {"type": "string"},
  }
});
```

### Option 4: Annotations (with build_runner)

```dart
@HttpContractSchema(mode: 'strict', version: '1.0')
class UserContract {
  @contractRequired
  final String id;

  @contractRequired
  final String name;

  @contractOptional
  final int? age;

  UserContract({required this.id, required this.name, this.age});
}
```

Then run:

```bash
dart run build_runner build
```

### Validate

```dart
final result = userContract.validate(responseJson);

result.when(
  valid: () => print('Contract matched!'),
  invalid: (violations) {
    for (final v in violations) {
      print('${v.fieldPath}: ${v.message}');
    }
  },
);

// Or throw on failure:
userContract.validate(responseJson).throwIfInvalid();
```

## API Reference

### HttpContract

| Method / Property | Description |
|---|---|
| `validate(Map<String, dynamic> json)` | Validates JSON against the contract |
| `upgrade({version, added, removed})` | Creates a new contract version |
| `copyWith({fields, mode, version})` | Copies with overrides |
| `HttpContract.fromJson(Map sampleJson)` | Auto-generate from sample JSON |
| `HttpContract.fromJsonSchema(Map schema)` | Generate from JSON Schema |

### ContractField Constructors

| Constructor | Description |
|---|---|
| `ContractField.required(type:)` | Required field with the given type |
| `ContractField.optional(type:)` | Optional field (no violation if missing) |
| `ContractField.nullable(type:)` | Required but can be `null` |
| `ContractField.nested(nestedContract:)` | Nested object with its own contract |
| `ContractField.list({listItemContract:})` | List field, optionally validating items |
| `ContractField.deprecated(type:, message:)` | Deprecated field that triggers a warning |

### FieldType

| Value | Dart types matched |
|---|---|
| `string` | `String` |
| `number` | `int`, `double`, `num` |
| `boolean` | `bool` |
| `list` | `List` |
| `map` | `Map` |
| `any` | Any type (no checking) |

### ViolationType

| Type | Meaning | Example |
|---|---|---|
| `missingRequiredField` | A required field is absent | `"name"` missing from response |
| `typeMismatch` | Field has wrong type | Expected `number`, got `String` |
| `unexpectedField` | Extra field in strict mode | `"foo"` not in contract |
| `nullableViolation` | Non-nullable field is `null` | `"id": null` |
| `deprecatedFieldUsed` | Deprecated field present | Old `"legacy_id"` still returned |
| `invalidListItem` | List item doesn't match contract | Item missing required field |
| `invalidNestedObject` | Nested object doesn't match | Nested field has wrong type |

### ContractMode

| Mode | Behavior |
|---|---|
| `strict` | Flags any fields not defined in the contract as violations |
| `lenient` | Ignores extra fields not in the contract (default) |

## Global Configuration

```dart
HttpContractConfig.setup(
  onViolation: ViolationBehavior.throwInCI,
  enableInRelease: false,
  logPrefix: '[HttpContract]',
);
```

## Using with Dio

Validate responses and request bodies automatically via Dio interceptors.

```dart
import 'package:dio/dio.dart';
import 'package:api_contract_validator/api_contract_validator.dart';

void main() async {
  // Configure (throws in CI if CI=true)
  HttpContractConfig.setup(
    onViolation: ViolationBehavior.throwInCI,
    enableInRelease: false,
  );

  // Define contracts
  final post = HttpContract(
    mode: ContractMode.strict,
    fields: {
      'id':    ContractField.required(type: FieldType.number),
      'title': ContractField.required(type: FieldType.string),
      'body':  ContractField.optional(type: FieldType.string),
      'userId': ContractField.required(type: FieldType.number),
    },
  );

  // Endpoint returns a Map with a list of posts
  final postsList = HttpContract(
    mode: ContractMode.lenient,
    fields: {
      'posts': ContractField.list(listItemContract: post),
    },
  );

  // Path pattern -> contract mappings
  final responseContracts = {
    '/posts': postsList,
    '/posts/{id}': post,
  };

  // Optional: validate outgoing request bodies too
  final requestContracts = <String, HttpContract>{
    '/posts': HttpContract(fields: {
      'title': ContractField.required(type: FieldType.string),
      'body':  ContractField.optional(type: FieldType.string),
      'userId': ContractField.required(type: FieldType.number),
    }, mode: ContractMode.strict),
  };

  final dio = Dio();
  dio.interceptors.add(RequestContractInterceptor(requestContracts));
  dio.interceptors.add(ContractInterceptor(responseContracts));

  final res = await dio.get('https://dummyjson.com/posts');
  print(res.statusCode);
}
```

### ViolationBehavior

| Behavior | Description |
|---|---|
| `log` | Print violations to console (default) |
| `warn` | Print as warnings |
| `throwAlways` | Always throw `ContractViolationException` |
| `throwInCI` | Throw only when `CI=true` env var is set |
| `silent` | Ignore violations |

## CI/CD Integration

Set `CI=true` in your CI environment and configure:

```dart
HttpContractConfig.setup(
  onViolation: ViolationBehavior.throwInCI,
);
```

Contract violations will throw exceptions in CI, failing your pipeline before broken API assumptions reach production.

## Version Upgrades

Track contract evolution over time:

```dart
final v1 = HttpContract(version: '1.0', fields: { ... });

final v2 = v1.upgrade(
  version: '2.0',
  added: {'avatar': ContractField.optional(type: FieldType.string)},
  removed: ['legacy_id'],
);
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.
