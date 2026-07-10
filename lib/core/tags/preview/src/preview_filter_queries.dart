// Project imports:
import '../../../boorus/booru/types.dart';
import 'tag_preview_provider.dart';

/// Each booru tags animated media differently; some barely use `video` at
/// all. These queries use the local OR syntax (`a|b`) which the query
/// composer translates into each booru's native OR form. On boorus without
/// OR support the first (best) tag of the group is used.
String? previewFilterQuery(TagPreviewFilterMode mode, BooruType booruType) =>
    switch (mode) {
      TagPreviewFilterMode.off => null,
      TagPreviewFilterMode.animated => switch (booruType) {
        // Danbooru's animated covers video + gif and keeps within tag limits.
        BooruType.danbooru => 'animated',
        BooruType.gelbooru => 'animated|video|animated_gif',
        BooruType.gelbooruV2 => 'animated|video|webm|gif',
        // e621 consistently tags all moving media as animated.
        BooruType.e621 => 'animated',
        BooruType.sankaku => 'animated|video',
        BooruType.philomena => 'animated|webm',
        BooruType.szurubooru => 'type:animation,video',
        _ => 'animated',
      },
      TagPreviewFilterMode.video => switch (booruType) {
        BooruType.danbooru => 'video',
        BooruType.gelbooru => 'video|webm',
        BooruType.gelbooruV2 => 'video|webm|mp4',
        // e621 hosts videos as webm; the video tag is barely used.
        BooruType.e621 => 'webm',
        BooruType.sankaku => 'video|webm|mp4',
        BooruType.philomena => 'webm',
        BooruType.szurubooru => 'type:video',
        // Shimmie sites like rule34.paheal mostly tag videos as webm.
        BooruType.shimmie2 => 'webm',
        _ => 'video',
      },
    };

String previewQueryFor({
  required String tag,
  required TagPreviewFilterMode mode,
  required BooruType booruType,
}) => switch (previewFilterQuery(mode, booruType)) {
  final extra? => '$tag $extra',
  null => tag,
};
