// ignore_for_file: avoid_print

import 'package:api_contract/api_contract.dart';

import 'post.dart'; // brings in generated `postContract`

void main() async {
  // ══════════════════════════════════════════════════════════════════
  // SECTION 1: Manual Contract Validation Examples
  // ══════════════════════════════════════════════════════════════════
  await _manualContractExamples();

  print('\n${'═' * 70}\n');

  // ══════════════════════════════════════════════════════════════════
  // SECTION 2: Repository Pattern Integration
  // ══════════════════════════════════════════════════════════════════
  await _repositoryPatternExample();
}

// ────────────────────────────────────────────────────────────────────
// Manual Contract Validation Examples
// ────────────────────────────────────────────────────────────────────
Future<void> _manualContractExamples() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║        MANUAL CONTRACT VALIDATION EXAMPLES                    ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // ── Global Configuration ────────────────────────────────────────────
  ApiContractConfig.setup(
    onViolation: ViolationBehavior.log,
    enableInRelease: false,
    logPrefix: '[Contract]',
  );

  // ── Option 1: Manual Contract Definition ────────────────────────────
  final manualContract = ApiContract(
    mode: ContractMode.strict,
    version: '1.0',
    fields: {
      'id': const ContractField.required(type: FieldType.string),
      'name': const ContractField.required(type: FieldType.string),
      'age': const ContractField.optional(type: FieldType.number),
      'email': const ContractField.required(type: FieldType.string),
      'address': ContractField.nested(
        nestedContract: ApiContract(fields: {
          'city': const ContractField.required(type: FieldType.string),
          'zip': const ContractField.optional(type: FieldType.string),
        }),
      ),
      'tags': const ContractField.list(),
    },
  );

  // ── Option 2: Auto-generate from JSON Sample ───────────────────────
  final fromJsonContract = ApiContract.fromJson({
    'id': '123',
    'name': 'Ahmed',
    'age': 25,
    'email': 'ahmed@test.com',
    'address': {'city': 'Riyadh', 'zip': '12345'},
    'tags': ['flutter', 'dart'],
  });

  // ── Option 3: Generate from JSON Schema ────────────────────────────
  final fromSchemaContract = ApiContract.fromJsonSchema({
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
// Repository Pattern Integration Example
// ────────────────────────────────────────────────────────────────────
Future<void> _repositoryPatternExample() async {
  print('╔═══════════════════════════════════════════════════════════════╗');
  print('║        REPOSITORY PATTERN INTEGRATION                         ║');
  print('╚═══════════════════════════════════════════════════════════════╝\n');

  // Configure global behavior
  ApiContractConfig.setup(
    onViolation: ViolationBehavior.throwInCI, // Throws in CI, logs otherwise
    enableInRelease: false,
    logPrefix: '[Contract]',
  );

  // Create a repository instance
  final postRepo = PostRepository();

  // Fetch post with automatic validation
  print('Fetching post with ID 1...\n');
  final result = await postRepo.getPost(1);

  result.when(
    success: (post) {
      print('✓ Success! Post title: ${post['title']}');
    },
    failure: (error) {
      print('✗ Failed: $error');
    },
  );
}

void _validateAndPrint(ApiContract contract, Map<String, dynamic> json) {
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

// ════════════════════════════════════════════════════════════════════
// Example Repository Implementation
// ════════════════════════════════════════════════════════════════════

/// A simple result wrapper similar to your ApiResult
class ApiResult<T> {
  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  final T? data;
  final String? error;

  void when({
    required void Function(T data) success,
    required void Function(String error) failure,
  }) {
    if (error != null) {
      failure(error!);
    } else {
      success(data as T);
    }
  }
}

/// Example repository showing how to integrate contract validation
/// This matches your LessonRepo pattern
class PostRepository {
  // In a real app, this would be injected
  final PostApiService _apiService = PostApiService();

  /// Fetches a post and validates the response against the contract
  Future<ApiResult<Map<String, dynamic>>> getPost(int postId) async {
    try {
      // 1. Make the API call
      final response = await _apiService.fetchPost(postId);

      // 2. Validate the response against the contract
      final validationResult = postContract.validate(response);

      // 3. Throw if validation fails (in CI mode) or log warnings
      validationResult.throwIfInvalid();

      // 4. Return success if validation passes
      return ApiResult.success(response);
    } catch (error) {
      // Handle any errors (network, validation, etc.)
      return ApiResult.failure('Error fetching post: $error');
    }
  }

  /// Alternative approach: Manual violation handling
  Future<ApiResult<Map<String, dynamic>>> getPostWithManualValidation(
    int postId,
  ) async {
    try {
      final response = await _apiService.fetchPost(postId);

      // Validate and handle violations manually
      final validationResult = postContract.validate(response);

      validationResult.when(
        valid: () {
          print('✓ Response contract validated successfully');
        },
        invalid: (violations) {
          print('⚠ Contract violations detected:');
          for (final v in violations) {
            print('  - ${v.fieldPath}: ${v.message}');
          }
          // You can decide whether to throw or continue based on severity
        },
      );

      return ApiResult.success(response);
    } catch (error) {
      return ApiResult.failure('Error: $error');
    }
  }
}

/// Mock API service (in real app, this would use Dio/http)
class PostApiService {
  Future<Map<String, dynamic>> fetchPost(int id) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate API response
    return {
      'id': id,
      'title': 'Sample Post Title',
      'body': 'This is the post body content.',
      'userId': 1,
      'reactions': {
        'likes': 42,
        'dislikes': 3,
      },
      'tags': ['flutter', 'dart', 'api'],
      'views': 1234,
    };
  }
}
