[![pub package](https://img.shields.io/pub/v/api_contract.svg)](https://pub.dev/packages/api_contract)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/dart-%3E%3D3.0-blue.svg)](https://dart.dev)

# api_contract

A runtime API response contract validator for Flutter/Dart.
Detect mismatches between your expected API contracts and actual server responses **before** they silently break your app.

## 🎯 The Problem

Backend APIs change. Fields get renamed, types shift from `int` to `String`, optional fields become null, and new fields appear without warning. Your app keeps running — but with wrong data, broken UI, or silent failures.

`api_contract` catches these mismatches at runtime by validating API responses against a contract you define.

## ✨ Features

- ✅ **Runtime validation** - Catch API contract violations before they cause bugs
- ✅ **Multiple contract modes** - Strict or lenient validation
- ✅ **Type checking** - Validate field types (string, number, boolean, list, map)
- ✅ **Nested objects** - Support for complex nested structures
- ✅ **Built-in types** - DateTime, Uri, Duration auto-detected
- ✅ **Code generation** - Auto-generate contracts from model classes
- ✅ **Repository pattern** - Clean integration with repository layer
- ✅ **CI/CD friendly** - Throw errors in CI, log warnings in development
- ✅ **Zero runtime overhead in release** - Disable validation in production

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  api_contract: ^0.2.0

dev_dependencies:
  api_contract_generator: ^0.1.0
  build_runner: ^2.4.13
```

Then run:

```bash
dart pub get
```

## 🚀 Quick Start

### Option 1: Auto-Generate from Model (Recommended)

**1. Annotate your model:**

```dart
import 'package:api_contract/api_contract.dart';
import 'package:api_contract_generator/api_contract_generator.dart';

part 'user.g.dart';

@ApiContractSchema(mode: ContractMode.strict, version: '1.0')
class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;

  @optional
  final String? avatar;  // Can be missing from response

  final DateTime createdAt;  // Auto-detected as string in JSON
}
```

**2. Generate contract:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**3. Use in repository:**

```dart
class UserRepo {
  Future<ApiResult<User>> getUser(int userId) async {
    try {
      final response = await _apiService.getUser(userId);

      // Validate response
      final validationResult = userContract.validate(response.toJson());
      validationResult.throwIfInvalid();

      return ApiResult.success(response);
    } catch (error) {
      return ApiResult.failure(error);
    }
  }
}
```

### Option 2: Manual Contract Definition

```dart
import 'package:api_contract/api_contract.dart';

final userContract = ApiContract(
  mode: ContractMode.strict,
  version: '1.0',
  fields: {
    'id':    ContractField.required(type: FieldType.number),
    'name':  ContractField.required(type: FieldType.string),
    'email': ContractField.required(type: FieldType.string),
    'avatar': ContractField.optional(type: FieldType.string),
    'createdAt': ContractField.required(type: FieldType.string),
  },
);

// Validate
final result = userContract.validate(responseJson);
result.throwIfInvalid();
```

## 📖 Usage Guide

### Contract Modes

```dart
// Strict mode - flags unexpected fields as violations
@ApiContractSchema(mode: ContractMode.strict)

// Lenient mode - ignores extra fields (default)
@ApiContractSchema(mode: ContractMode.lenient)
```

### Field Annotations

```dart
class Post {
  final String title;        // Required by default

  @optional
  final String? description; // Can be missing from response

  @nullable
  final String? author;      // Must be present but can be null

  final DateTime createdAt;  // Auto-detected as string in JSON
}
```

**Difference:**
- `@optional`: Field can be **missing** from JSON → `ContractField.optional()`
- `@nullable`: Field must be **present** but value can be `null` → `ContractField.nullable()`

### Supported Types

| Dart Type | JSON Type | Auto-Detected |
|-----------|-----------|---------------|
| `String` | string | ✅ |
| `int`, `double`, `num` | number | ✅ |
| `bool` | boolean | ✅ |
| `List` | array | ✅ |
| `Map` | object | ✅ |
| `DateTime` | string | ✅ |
| `Uri` | string | ✅ |
| `Duration` | number | ✅ |
| Custom classes | nested | ✅ |

### Repository Pattern Integration

```dart
class LessonRepo {
  final LessonApiService _apiService;

  Future<ApiResult<Lesson>> getLesson(int id) async {
    try {
      // 1. Fetch from API
      final response = await _apiService.getLesson(id);

      // 2. Validate contract
      final validationResult = lessonContract.validate(response.toJson());

      // 3. Handle violations
      validationResult.when(
        valid: () => print('✓ Valid response'),
        invalid: (violations) {
          for (final v in violations) {
            print('✗ ${v.fieldPath}: ${v.message}');
          }
        },
      );

      // 4. Throw if invalid (in CI mode)
      validationResult.throwIfInvalid();

      return ApiResult.success(response);
    } catch (error) {
      return ApiResult.failure(error);
    }
  }
}
```

### Global Configuration

```dart
void main() {
  ApiContractConfig.setup(
    onViolation: ViolationBehavior.throwInCI,  // Throw in CI, log otherwise
    enableInRelease: false,  // Disable in production
    logPrefix: '[Contract]',
  );

  runApp(MyApp());
}
```

**ViolationBehavior options:**
- `log` - Print violations (default)
- `warn` - Print warnings
- `throwAlways` - Always throw exception
- `throwInCI` - Throw only when `CI=true` env var is set
- `silent` - Ignore violations

## 🧪 CI/CD Integration

Set `CI=true` in your CI environment:

```yaml
# GitHub Actions
env:
  CI: true
```

Then configure:

```dart
ApiContractConfig.setup(
  onViolation: ViolationBehavior.throwInCI,
);
```

Contract violations will fail your pipeline before broken assumptions reach production.

## 📚 API Reference

### ApiContract

| Method | Description |
|--------|-------------|
| `validate(Map<String, dynamic> json)` | Validates JSON against contract |
| `upgrade({version, added, removed})` | Creates new contract version |
| `copyWith({fields, mode, version})` | Copies with overrides |
| `ApiContract.fromJson(Map)` | Auto-generate from sample JSON |
| `ApiContract.fromJsonSchema(Map)` | Generate from JSON Schema |

### ContractField

| Constructor | Description |
|-------------|-------------|
| `ContractField.required(type:)` | Required field |
| `ContractField.optional(type:)` | Optional (can be missing) |
| `ContractField.nullable(type:)` | Required but can be null |
| `ContractField.nested(nestedContract:)` | Nested object |
| `ContractField.list({listItemContract:})` | List field |
| `ContractField.deprecated(type:, message:)` | Deprecated field |

### ViolationType

| Type | Description |
|------|-------------|
| `missingRequiredField` | Required field is absent |
| `typeMismatch` | Field has wrong type |
| `unexpectedField` | Extra field in strict mode |
| `nullableViolation` | Non-nullable field is null |
| `deprecatedFieldUsed` | Deprecated field present |

## 🎓 Examples

Check the [example](example/) directory for complete examples:
- [main.dart](example/main.dart) - Full featured example with repository pattern
- [post.dart](example/post.dart) - Simple model with annotations

## 📝 Version Upgrades

Track contract evolution:

```dart
final v1 = ApiContract(version: '1.0', fields: {...});

final v2 = v1.upgrade(
  version: '2.0',
  added: {'avatar': ContractField.optional(type: FieldType.string)},
  removed: ['legacyId'],
);
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

## 🔗 Related Packages

- [api_contract_generator](https://pub.dev/packages/api_contract_generator) - Code generator companion package

## 💡 Tips

- Use `ContractMode.strict` during development to catch all changes
- Switch to `ContractMode.lenient` if backend adds optional fields frequently
- Enable `throwInCI` to fail builds on contract violations
- Disable validation in production builds for performance
- Use `@optional` for fields that might be missing
- Use `@nullable` for fields that are always present but can be null

## ⚡ Performance

- Zero overhead in release builds (when `enableInRelease: false`)
- Minimal overhead in debug builds
- Efficient type checking and validation
- No reflection used

---

Made with ❤️ for Flutter developers tired of silent API breakages.
