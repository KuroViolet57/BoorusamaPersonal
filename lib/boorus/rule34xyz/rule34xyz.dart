// Project imports:
import '../../core/boorus/booru/types.dart';
import '../../core/boorus/engine/types.dart';
import 'rule34xyz_builder.dart';
import 'rule34xyz_repository.dart';

BooruComponents createRule34xyz() => BooruComponents(
  parser: DefaultBooruParser(
    config: BooruYamlConfigs.rule34xyz,
  ),
  createBuilder: Rule34XyzBuilder.new,
  createRepository: (ref) => Rule34XyzRepository(ref: ref),
);
