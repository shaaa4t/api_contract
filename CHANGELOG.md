## 0.2.0

- Added `HttpContract.fromJson()` to auto-generate contracts from sample JSON responses.
- Added `HttpContract.fromJsonSchema()` to generate contracts from JSON Schema / OpenAPI / Swagger schemas.
- Support for `$ref` resolution in JSON Schema.

## 0.1.0

- Initial release.
- Core contract validation with `HttpContract`, `ContractField`, and `Validator`.
- Support for `string`, `number`, `boolean`, `list`, `map`, and `any` field types.
- Nested object and list item validation.
- Strict and lenient validation modes.
- `ContractConfig` for global violation behavior configuration.
- `Reporter` for configurable violation reporting.
- `ContractValidationResult` with `when()` and `throwIfInvalid()`.
- Contract versioning and `upgrade()` method.
