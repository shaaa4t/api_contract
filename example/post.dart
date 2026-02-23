import 'package:api_contract/api_contract.dart';
import 'package:api_contract_generator/api_contract_generator.dart';

part 'post.g.dart';

@ApiContractSchema(mode: ContractMode.strict, version: '1.0')
class Post {
  Post({
    required this.id,
    required this.title,
    this.body,
    required this.tags,
    required this.reactions,
    required this.views,
    required this.userId,
  });

  final int id;
  final String title;
  final String? body;
  final List<String> tags;
  final Reactions reactions;
  final int views;
  final int userId;
}

@ApiContractSchema()
class Reactions {
  Reactions({required this.likes, required this.dislikes});

  final int likes;
  final int dislikes;
}
