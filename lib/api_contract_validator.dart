/// Runtime API response contract validator for Flutter/Dart.
///
/// Detects mismatches between expected API contracts and actual responses,
/// preventing silent bugs when the backend changes its response structure.
library;

export 'src/contract.dart' show HttpContract, ContractMode;
export 'src/dio_contract_interceptor.dart' show ContractInterceptor;
export 'src/request_contract_interceptor.dart' show RequestContractInterceptor;
export 'src/contract_config.dart'
    show HttpContractConfig, ViolationBehavior;
export 'src/contract_field.dart' show ContractField, FieldType;
export 'src/reporter.dart' show Reporter;
export 'src/violation.dart'
    show
        ContractValidationResult,
        ContractViolationException,
        Violation,
        ViolationType;
