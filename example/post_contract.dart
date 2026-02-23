import 'package:api_contract_validator/api_contract_validator.dart';
import 'package:api_contract_validator_generator/api_contract_validator_generator.dart';

part 'post_contract.g.dart';

@HttpContractSchema(mode: 'strict', version: '1.0')
class PostContract {
  PostContract(
      {required this.id,
      required this.title,
      required this.body,
      required this.tags,
      required this.reactions,
      required this.views,
      required this.userId});

  @contractRequired
  final int id;

  @contractRequired
  final String title;

  @contractRequired
  final String body;

  @listField
  final List<String> tags;

  @nested
  final ReactionsContract reactions;

  @contractRequired
  final int views;

  @contractRequired
  final int userId;
}

@HttpContractSchema()
class ReactionsContract {
  ReactionsContract({required this.likes, required this.dislikes});

  @contractRequired
  final int likes;

  @contractRequired
  final int dislikes;
}
