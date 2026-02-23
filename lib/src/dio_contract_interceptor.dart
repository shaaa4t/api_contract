import 'package:dio/dio.dart';

import 'contract.dart';
import 'reporter.dart';

/// A Dio [Interceptor] that automatically validates HTTP responses against
/// registered [HttpContract]s based on URL path patterns.
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(ContractInterceptor({
///   '/posts': postContract,
///   '/posts/{id}': postContract,
///   '/users/{id}': userContract,
/// }));
/// ```
///
/// Path patterns support `{placeholder}` segments that match any single path
/// segment (e.g. `/users/{id}` matches `/users/42`).
///
/// - **Map responses** are validated directly.
/// - **List responses** validate each Map item individually.
/// - **Other data types** (String, null, etc.) are silently skipped.
///
/// Violations are reported via [Reporter.report], respecting [HttpContractConfig].
class ContractInterceptor extends Interceptor {
  /// Creates a [ContractInterceptor] with the given path-to-contract mappings.
  ContractInterceptor(this._contracts);

  /// A map of path patterns to contracts.
  ///
  /// Patterns may include `{placeholder}` segments for dynamic path parts.
  final Map<String, HttpContract> _contracts;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final path = response.requestOptions.path;
    final uri = Uri.tryParse(path);
    final matchPath = uri != null && uri.hasScheme ? uri.path : path;

    // Strip trailing slash for consistent matching.
    final normalizedPath = matchPath.length > 1 && matchPath.endsWith('/')
        ? matchPath.substring(0, matchPath.length - 1)
        : matchPath;

    final contract = _findContract(normalizedPath);

    if (contract != null) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        Reporter.report(contract.validate(data));
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            Reporter.report(contract.validate(item));
          }
        }
      }
      // Other types (String, null, etc.) are silently skipped.
    }

    handler.next(response);
  }

  /// Finds a contract matching the given [path].
  ///
  /// Tries exact match first, then checks placeholder patterns.
  HttpContract? _findContract(String path) {
    // Exact match.
    if (_contracts.containsKey(path)) {
      return _contracts[path];
    }

    // Placeholder match.
    for (final entry in _contracts.entries) {
      if (_matchesPattern(entry.key, path)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Returns `true` if [pattern] matches [path].
  ///
  /// A `{...}` segment in the pattern matches any single path segment.
  static bool _matchesPattern(String pattern, String path) {
    final patternSegments = _segments(pattern);
    final pathSegments = _segments(path);

    if (patternSegments.length != pathSegments.length) return false;

    for (var i = 0; i < patternSegments.length; i++) {
      final p = patternSegments[i];
      if (p.startsWith('{') && p.endsWith('}')) continue;
      if (p != pathSegments[i]) return false;
    }

    return true;
  }

  /// Splits a path into non-empty segments.
  static List<String> _segments(String path) {
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}
