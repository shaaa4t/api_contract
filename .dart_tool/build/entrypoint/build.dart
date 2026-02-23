// @dart=3.6
// ignore_for_file: directives_ordering
// build_runner >=2.4.16
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner/src/build_plan/builder_factories.dart' as _i1;
import 'package:api_contract_generator/api_contract_generator.dart' as _i2;
import 'package:source_gen/builder.dart' as _i3;
import 'dart:io' as _i4;
import 'package:build_runner/src/bootstrap/processes.dart' as _i5;

final _builderFactories = _i1.BuilderFactories(
  {
    'api_contract_generator:contract': [_i2.contractBuilder],
    'source_gen:combining_builder': [_i3.combiningBuilder],
  },
  postProcessBuilderFactories: {'source_gen:part_cleanup': _i3.partCleanup},
);
void main(List<String> args) async {
  _i4.exitCode = await _i5.ChildProcess.run(
    args,
    _builderFactories,
  )!;
}
