// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:api_contract_validator/api_contract_validator.dart';

import 'post_contract.dart'; // brings in generated `postContract`

void main() async {
  // ══════════════════════════════════════════════════════════════════
  // SECTION 1: Manual Contract Validation Examples
  // ══════════════════════════════════════════════════════════════════
  await _manualContractExamples();

  print('\n${'═' * 70}\n');

  // ══════════════════════════════════════════════════════════════════
  // SECTION 2: Dio Integration with ContractInterceptor
  // ══════════════════════════════════════════════════════════════════
  await _dioContractInterceptorExample();
}

// ────────────────────────────────────────────────────────────────────
// Manual Contract Validation Examples
// ────────────────────────────────────────────────────────────────────
Future<void> _manualContractExamples() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║        MANUAL CONTRACT VALIDATION EXAMPLES                    ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // ── Global Configuration ────────────────────────────────────────────
  HttpContractConfig.setup(
    onViolation: ViolationBehavior.log,
    enableInRelease: false,
    logPrefix: '[Contract]',
  );

  // ── Option 1: Manual Contract Definition ────────────────────────────
  final manualContract = HttpContract(
    mode: ContractMode.strict,
    version: '1.0',
    fields: {
      'id': const ContractField.required(type: FieldType.string),
      'name': const ContractField.required(type: FieldType.string),
      'age': const ContractField.optional(type: FieldType.number),
      'email': const ContractField.required(type: FieldType.string),
      'address': ContractField.nested(
        nestedContract: HttpContract(fields: {
          'city': const ContractField.required(type: FieldType.string),
          'zip': const ContractField.optional(type: FieldType.string),
        }),
      ),
      'tags': const ContractField.list(),
    },
  );

  // ── Option 2: Auto-generate from JSON Sample ───────────────────────
  final fromJsonContract = HttpContract.fromJson({
    'id': '123',
    'name': 'Ahmed',
    'age': 25,
    'email': 'ahmed@test.com',
    'address': {'city': 'Riyadh', 'zip': '12345'},
    'tags': ['flutter', 'dart'],
  });

  // ── Option 3: Generate from JSON Schema ────────────────────────────
  final fromSchemaContract = HttpContract.fromJsonSchema({
    'type': 'object',
    'required': ['id', 'name', 'email'],
    'properties': {
      'id': {'type': 'string'},
      'name': {'type': 'string'},
      'age': {'type': 'number'},
      'email': {'type': 'string'},
    },
  });

  // ── Validate a response ────────────────────────────────────────────
  final responseJson = {
    'id': '123',
    'name': 'Ahmed',
    'email': 'ahmed@test.com',
    'address': {'city': 'Riyadh'},
    'tags': ['flutter'],
  };

  print('--- Manual Contract ---');
  _validateAndPrint(manualContract, responseJson);

  print('\n--- From JSON Contract ---');
  _validateAndPrint(fromJsonContract, responseJson);

  print('\n--- From Schema Contract ---');
  _validateAndPrint(fromSchemaContract, responseJson);

  // ── throwIfInvalid ────────────────────────────────────────────────
  print('\n--- throwIfInvalid demo ---');
  try {
    fromSchemaContract.validate(responseJson).throwIfInvalid();
    print('Validation passed!');
  } on ContractViolationException catch (e) {
    print('Caught: $e');
  }

  // ── Upgrade contract version ──────────────────────────────────────
  print('\n--- Contract Upgrade ---');
  final v2 = manualContract.upgrade(
    version: '2.0',
    added: {
      'avatar': const ContractField.optional(type: FieldType.string),
    },
    removed: ['age'],
  );
  print('Upgraded to ${v2.version}');
  print('Fields: ${v2.fields.keys.toList()}');
}

// ────────────────────────────────────────────────────────────────────
// Dio Integration with ContractInterceptor
// ────────────────────────────────────────────────────────────────────
Future<void> _dioContractInterceptorExample() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║        DIO INTEGRATION WITH CONTRACT INTERCEPTOR              ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // 1) Configure how violations are handled
  HttpContractConfig.setup(
    onViolation: ViolationBehavior.throwInCI, // set CI=true to throw in CI
    enableInRelease: false,
    logPrefix: '[Contract]',
  );

  // 2) Build a wrapper contract for the endpoint shape:
  // dummyjson /posts returns a Map with a `posts` list and pagination fields.
  final postsListContract = HttpContract(
    mode: ContractMode.lenient, // allow extra fields not declared below
    fields: {
      'posts': ContractField.list(
        listItemContract: postContract, // validate each item as a Post
      ),
      // Optionally enable these if you want strict checking:
      // 'total': ContractField.required(type: FieldType.number),
      // 'skip': ContractField.required(type: FieldType.number),
      // 'limit': ContractField.required(type: FieldType.number),
    },
  );

  // 3) Register path->contract mapping for this run
  final contracts = <String, HttpContract>{
    '/posts': postsListContract,
  };

  // 4) Create Dio and add the ContractInterceptor
  final dio = Dio();
  dio.interceptors.add(ContractInterceptor(contracts));

  try {
    print('Fetching posts from https://dummyjson.com/posts...\n');
    final response = await dio.get('https://dummyjson.com/posts');
    // If violations occur, they will be logged (or thrown in CI) automatically.
    print('Status: ${response.statusCode}');
  } on DioException catch (e) {
    print('Dio error: ${e.response?.statusCode} ${e.message}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}

void _validateAndPrint(HttpContract contract, Map<String, dynamic> json) {
  final result = contract.validate(json);
  result.when(
    valid: () => print('Contract matched!'),
    invalid: (violations) {
      for (final v in violations) {
        print('[${v.type.name}] ${v.fieldPath}: ${v.message}');
      }
    },
  );
}
