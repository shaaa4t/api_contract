## 0.2.0

### ✨ New Features
- **Code Generation Support**: Auto-generate contracts from model classes using `@ApiContractSchema` annotation
- **Built-in Types**: Auto-detection for `DateTime`, `Uri`, `Duration`, `BigInt`, and `RegExp`
- **Field Annotations**: `@optional` and `@nullable` annotations for fine-grained control
- **Repository Pattern**: Clean integration examples for repository layer validation
- **Enum Support**: `ContractMode` is now an enum instead of string-based
- Added `ApiContract.fromJson()` to auto-generate contracts from sample JSON responses
- Added `ApiContract.fromJsonSchema()` to generate contracts from JSON Schema / OpenAPI / Swagger schemas
- Support for `$ref` resolution in JSON Schema

### 🔧 Improvements
- Removed Dio interceptor dependency - validation now works with any HTTP client
- Moved `dio` to dev_dependencies (only needed for examples)
- Better handling of nullable types in code generation
- Improved error messages for contract violations
- Updated documentation with comprehensive examples

### 🐛 Bug Fixes
- Fixed nullable type name generation (e.g., `OwnerModel?` → `ownerModelContract`)
- Fixed field annotation priority in code generator
- Corrected enum mode reading in annotation processor
- Fixed `@nullable` annotation not being respected in `fromModel` mode

### 📚 Documentation
- Complete rewrite of README with modern examples
- Added repository pattern integration guide
- Added CI/CD integration examples
- Improved API reference documentation

### ⚠️ Breaking Changes
- `ContractMode` is now an enum: use `ContractMode.strict` instead of `'strict'`
- Removed `ContractInterceptor` and `RequestContractInterceptor` (Dio-specific)
- Package focuses on repository pattern instead of interceptors

## 0.1.0

### Initial Release
- Core contract validation with `ApiContract`, `ContractField`, and `Validator`
- Support for `string`, `number`, `boolean`, `list`, `map`, and `any` field types
- Nested object and list item validation
- Strict and lenient validation modes
- `ContractConfig` for global violation behavior configuration
- `Reporter` for configurable violation reporting
- `ContractValidationResult` with `when()` and `throwIfInvalid()`
- Contract versioning and `upgrade()` method
