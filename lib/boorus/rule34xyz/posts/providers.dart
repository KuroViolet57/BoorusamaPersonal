// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../core/configs/config/types.dart';
import '../../../core/posts/post/providers.dart';
import '../../../core/posts/post/types.dart';
import '../../../core/search/queries/providers.dart';
import '../../../core/settings/providers.dart';
import '../client_provider.dart';
import 'parser.dart';

final rule34xyzPostRepoProvider =
    Provider.family<PostRepository, BooruConfigSearch>(
      (ref, config) {
        final client = ref.watch(rule34xyzClientProvider(config.auth));
        final tagComposer = ref.watch(defaultTagQueryComposerProvider(config));

        return PostRepositoryBuilder(
          tagComposer: tagComposer,
          fetchSingle: (id, {options}) async {
            final numericId = id as NumericPostId?;

            if (numericId == null) return Future.value();

            final post = await client.getPost(id: numericId.value);
            return post != null ? postDtoToPost(client, post, null) : null;
          },
          fetch: (tags, page, {limit, options}) async {
            final result = await client.getPosts(
              tags: tags,
              page: page,
              limit: limit,
            );

            return result.items
                .map(
                  (e) => postDtoToPost(
                    client,
                    e,
                    PostMetadata(
                      page: page,
                      search: tags.join(' '),
                      limit: limit,
                    ),
                  ),
                )
                .toList()
                .toResult();
          },
          getSettings: () async => ref.read(imageListingSettingsProvider),
        );
      },
    );
