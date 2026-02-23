import 'contract_config.dart';
import 'violation.dart';

/// Reports contract validation results based on the current
/// [HttpContractConfig] settings.
///
/// In debug/development mode, violations are pretty-printed to the console.
/// In CI mode (when `CI=true` environment variable is set), violations
/// throw a [ContractViolationException].
class Reporter {
  const Reporter._();

  /// Reports the given [result] according to global configuration.
  ///
  /// This delegates to [HttpContractConfig.handleResult].
  static void report(ContractValidationResult result) {
    HttpContractConfig.handleResult(result);
  }
}
