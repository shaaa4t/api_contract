/// Runtime API response contract validator for Flutter/Dart.
///
/// Detects mismatches between expected API contracts and actual responses,
/// preventing silent bugs when the backend changes its response structure.
library;

export 'src/contract.dart' show ApiContract, ContractMode;
export 'src/contract_config.dart'
    show ApiContractConfig, ViolationBehavior;
export 'src/contract_field.dart' show ContractField, FieldType;
export 'src/reporter.dart' show Reporter;
export 'src/violation.dart'
    show
        ContractValidationResult,
        ContractViolationException,
        Violation,
        ViolationType;
