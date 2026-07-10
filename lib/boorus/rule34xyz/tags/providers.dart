// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../core/configs/config/types.dart';
import '../../../core/tags/autocompletes/types.dart';
import '../../../core/tags/local/providers.dart';
import '../../../core/tags/tag/types.dart';
import '../../../foundation/riverpod/riverpod.dart';
import '../client_provider.dart';
import 'parser.dart';

final rule34xyzTagsFromIdProvider = FutureProvider.autoDispose
    .family<List<Tag>, (BooruConfigAuth, int)>(
      (ref, params) async {
        ref.cacheFor(const Duration(minutes: 5));

        final (config, id) = params;
        final client = ref.watch(rule34xyzClientProvider(config));

        final post = await client.getPost(id: id);

        return post?.tags?.map(tagDtoToTag).toList() ?? [];
      },
    );

final rule34xyzTagExtractorProvider =
    Provider.family<TagExtractor, BooruConfigAuth>(
      (ref, config) {
        return TagExtractorBuilder(
          siteHost: config.url,
          tagCache: ref.watch(tagCacheRepositoryProvider.future),
          sorter: TagSorter.defaults(),
          fetcher: (post, options) async {
            final tags = await ref.read(
              rule34xyzTagsFromIdProvider((config, post.id)).future,
            );

            return tags;
          },
        );
      },
    );

final rule34xyzAutocompleteRepoProvider =
    Provider.family<AutocompleteRepository, BooruConfigAuth>(
      (ref, config) {
        final client = ref.watch(rule34xyzClientProvider(config));

        return AutocompleteRepositoryBuilder(
          autocomplete: (query) async {
            final tags = await client.getAutocomplete(query: query.text);

            return tags.map(tagDtoToAutocompleteData).toList();
          },
        );
      },
    );
