import 'contract_config.dart';
import 'violation.dart';

/// Reports contract validation results based on the current
/// [ApiContractConfig] settings.
///
/// In debug/development mode, violations are pretty-printed to the console.
/// In CI mode (when `CI=true` environment variable is set), violations
/// throw a [ContractViolationException].
class Reporter {
  const Reporter._();

  /// Reports the given [result] according to global configuration.
  ///
  /// This delegates to [ApiContractConfig.handleResult].
  static void report(ContractValidationResult result) {
    ApiContractConfig.handleResult(result);
  }
}
