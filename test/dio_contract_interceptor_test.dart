import 'package:dio/dio.dart';
import 'package:api_contract_validator/api_contract_validator.dart';
import 'package:test/test.dart';

void main() {
  late HttpContract contract;

  setUp(() {
    HttpContractConfig.setup(onViolation: ViolationBehavior.silent);
    contract = HttpContract(
      fields: {
        'id': const ContractField.required(type: FieldType.number),
        'title': const ContractField.required(type: FieldType.string),
      },
    );
  });

  tearDown(() {
    HttpContractConfig.reset();
  });

  Response<dynamic> _fakeResponse(String path, dynamic data) {
    return Response(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }

  group('path matching', () {
    test('matches exact path', () {
      final interceptor = ContractInterceptor({'/posts': contract});

      interceptor.onResponse(
        _fakeResponse('/posts', {'id': 1, 'title': 'Hello'}),
        ResponseInterceptorHandler(),
      );

      // If no exception, the interceptor found and ran the contract.
      // We verify by using throwAlways with an invalid response.
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      expect(
        () => interceptor.onResponse(
          _fakeResponse('/posts', {'id': 'wrong'}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('matches placeholder path', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts/{id}': contract});

      expect(
        () => interceptor.onResponse(
          _fakeResponse('/posts/42', {'id': 'wrong'}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('matches path with trailing slash', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      expect(
        () => interceptor.onResponse(
          _fakeResponse('/posts/', {'id': 'wrong'}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('does not match mismatched path', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      // Should NOT throw — path doesn't match, so no validation runs.
      interceptor.onResponse(
        _fakeResponse('/users', {'id': 'wrong'}),
        ResponseInterceptorHandler(),
      );
    });

    test('matches full URL by extracting path', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      expect(
        () => interceptor.onResponse(
          _fakeResponse(
              'https://example.com/posts', {'id': 'wrong'}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('matches placeholder in full URL path', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts/{id}': contract});

      expect(
        () => interceptor.onResponse(
          _fakeResponse(
              'https://example.com/posts/99', {'id': 'wrong'}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });
  });

  group('map response validation', () {
    test('valid map passes silently', () {
      final interceptor = ContractInterceptor({'/posts': contract});

      // No exception expected.
      interceptor.onResponse(
        _fakeResponse('/posts', {'id': 1, 'title': 'Hello'}),
        ResponseInterceptorHandler(),
      );
    });

    test('invalid map triggers violation', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      expect(
        () => interceptor.onResponse(
          _fakeResponse('/posts', {'id': 'not-a-number', 'title': 123}),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });
  });

  group('list response validation', () {
    test('validates each map item in list', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      // First item valid, second invalid — should throw.
      expect(
        () => interceptor.onResponse(
          _fakeResponse('/posts', [
            {'id': 1, 'title': 'OK'},
            {'id': 'bad'},
          ]),
          ResponseInterceptorHandler(),
        ),
        throwsA(isA<ContractViolationException>()),
      );
    });

    test('all valid list items pass', () {
      final interceptor = ContractInterceptor({'/posts': contract});

      interceptor.onResponse(
        _fakeResponse('/posts', [
          {'id': 1, 'title': 'First'},
          {'id': 2, 'title': 'Second'},
        ]),
        ResponseInterceptorHandler(),
      );
    });

    test('non-map list items are skipped', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      // List of strings — no map items, so no validation runs.
      interceptor.onResponse(
        _fakeResponse('/posts', ['hello', 'world']),
        ResponseInterceptorHandler(),
      );
    });
  });

  group('non-JSON data', () {
    test('string data is skipped', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      interceptor.onResponse(
        _fakeResponse('/posts', 'plain text'),
        ResponseInterceptorHandler(),
      );
    });

    test('null data is skipped', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      interceptor.onResponse(
        _fakeResponse('/posts', null),
        ResponseInterceptorHandler(),
      );
    });

    test('int data is skipped', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      interceptor.onResponse(
        _fakeResponse('/posts', 42),
        ResponseInterceptorHandler(),
      );
    });
  });

  group('unmatched paths', () {
    test('skips validation for unmatched path', () {
      HttpContractConfig.setup(onViolation: ViolationBehavior.throwAlways);
      final interceptor = ContractInterceptor({'/posts': contract});

      // Invalid data but path doesn't match — no throw.
      interceptor.onResponse(
        _fakeResponse('/comments', {'bad': 'data'}),
        ResponseInterceptorHandler(),
      );
    });
  });
}
