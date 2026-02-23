import 'package:dio/dio.dart';

import 'contract.dart';
import 'reporter.dart';

/// A Dio [Interceptor] that validates outgoing request bodies against
/// registered [HttpContract]s based on URL path patterns.
///
/// Use alongside [ContractInterceptor] (response validation) to cover both
/// directions.
class RequestContractInterceptor extends Interceptor {
  /// Path pattern to contract mappings for requests.
  final Map<String, HttpContract> _contracts;

  RequestContractInterceptor(this._contracts);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final uri = Uri.tryParse(path);
    final matchPath = uri != null && uri.hasScheme ? uri.path : path;

    final normalizedPath =
        matchPath.length > 1 && matchPath.endsWith('/')
            ? matchPath.substring(0, matchPath.length - 1)
            : matchPath;

    final contract = _findContract(normalizedPath);

    if (contract != null) {
      final data = options.data;
      if (data is Map<String, dynamic>) {
        Reporter.report(contract.validate(data));
      }
      // Other data types are skipped.
    }

    handler.next(options);
  }

  HttpContract? _findContract(String path) {
    if (_contracts.containsKey(path)) return _contracts[path];
    for (final entry in _contracts.entries) {
      if (_matchesPattern(entry.key, path)) return entry.value;
    }
    return null;
  }

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

  static List<String> _segments(String path) {
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }
}

