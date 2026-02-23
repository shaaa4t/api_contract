import 'dart:io';

import 'violation.dart';

/// Defines how violations are handled at runtime.
enum ViolationBehavior {
  /// Log violations to the console.
  log,

  /// Log violations as warnings.
  warn,

  /// Always throw a [ContractViolationException].
  throwAlways,

  /// Throw only when running in CI (checks for `CI=true` env var).
  throwInCI,

  /// Silently ignore violations.
  silent,
}

/// Global configuration for the HTTP contract tester.
///
/// Use [HttpContractConfig.setup] to configure behavior before running
/// validations.
///
/// ```dart
/// HttpContractConfig.setup(
///   onViolation: ViolationBehavior.throwInCI,
///   enableInRelease: false,
/// );
/// ```
class HttpContractConfig {
  static ViolationBehavior _onViolation = ViolationBehavior.log;
  static bool _enableInRelease = false;
  static String _logPrefix = '[HttpContract]';

  /// How violations should be handled.
  static ViolationBehavior get onViolation => _onViolation;

  /// Whether contract validation runs in release mode.
  static bool get enableInRelease => _enableInRelease;

  /// The prefix used when logging violations.
  static String get logPrefix => _logPrefix;

  /// Configures global contract validation behavior.
  ///
  /// - [onViolation]: How to handle violations (default: [ViolationBehavior.log]).
  /// - [enableInRelease]: Whether to run validation in release builds (default: false).
  /// - [logPrefix]: Prefix for log messages (default: `'[HttpContract]'`).
  static void setup({
    ViolationBehavior? onViolation,
    bool? enableInRelease,
    String? logPrefix,
  }) {
    if (onViolation != null) _onViolation = onViolation;
    if (enableInRelease != null) _enableInRelease = enableInRelease;
    if (logPrefix != null) _logPrefix = logPrefix;
  }

  /// Resets configuration to defaults. Useful in tests.
  static void reset() {
    _onViolation = ViolationBehavior.log;
    _enableInRelease = false;
    _logPrefix = '[HttpContract]';
  }

  /// Returns `true` if running in a CI environment.
  static bool get isCI {
    final ci = Platform.environment['CI'];
    return ci == 'true' || ci == '1';
  }

  /// Handles a validation result according to the current configuration.
  static void handleResult(ContractValidationResult result) {
    if (result.isValid) return;

    switch (_onViolation) {
      case ViolationBehavior.silent:
        break;
      case ViolationBehavior.log:
        for (final v in result.violations) {
          // ignore: avoid_print
          print('$_logPrefix ${v.fieldPath}: ${v.message}');
        }
        break;
      case ViolationBehavior.warn:
        for (final v in result.violations) {
          // ignore: avoid_print
          print('$_logPrefix WARNING: ${v.fieldPath}: ${v.message}');
        }
        break;
      case ViolationBehavior.throwAlways:
        throw ContractViolationException(result.violations);
      case ViolationBehavior.throwInCI:
        if (isCI) {
          throw ContractViolationException(result.violations);
        }
        for (final v in result.violations) {
          // ignore: avoid_print
          print('$_logPrefix ${v.fieldPath}: ${v.message}');
        }
        break;
    }
  }
}
