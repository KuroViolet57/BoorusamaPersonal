// Package imports:
import 'package:booru_clients/rule34xyz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../core/configs/config/types.dart';
import '../../core/http/client/providers.dart';

final rule34xyzClientProvider =
    Provider.family<Rule34XyzClient, BooruConfigAuth>(
      (ref, config) {
        final dio = ref.watch(defaultDioProvider(config));

        return Rule34XyzClient(
          dio: dio,
          baseUrl: config.url,
        );
      },
    );
