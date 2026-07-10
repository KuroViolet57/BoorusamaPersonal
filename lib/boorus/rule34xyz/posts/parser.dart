// Package imports:
import 'package:booru_clients/rule34xyz.dart';

// Project imports:
import '../../../core/posts/post/types.dart';
import '../../../core/posts/rating/types.dart';
import '../../../core/posts/sources/types.dart';
import 'types.dart';

const _kFullPic = ['10', '30', '1'];
const _kSamplePic = ['10', '30', '13', '33'];
const _kThumbPic = ['11', '31', '13', '33', '14', '34'];
const _kFullMov = ['100', '114', '113', '112'];
const _kSampleMov = ['113', '112', '111', '100'];

Rule34XyzPost postDtoToPost(
  Rule34XyzClient client,
  Rule34XyzPostDto e,
  PostMetadata? metadata,
) {
  // Video format ids are 100+ (mp4, hevc, av1 variants).
  final isVideo =
      e.files?.keys.any((key) => (int.tryParse(key) ?? 0) >= 100) ?? false;

  final thumbnail = client.firstFileUrl(e, _kThumbPic) ?? '';
  final original = isVideo
      ? client.firstFileUrl(e, _kFullMov) ?? ''
      : client.firstFileUrl(e, _kFullPic) ?? '';
  final sample = isVideo
      ? client.firstFileUrl(e, _kSampleMov) ?? original
      : client.firstFileUrl(e, _kSamplePic) ?? original;

  return Rule34XyzPost(
    id: e.id ?? 0,
    thumbnailImageUrl: thumbnail,
    sampleImageUrl: sample,
    originalImageUrl: original,
    tags:
        e.tags
            ?.map((t) => t.value?.replaceAll(' ', '_') ?? '')
            .where((t) => t.isNotEmpty)
            .toSet() ??
        {},
    rating: Rating.explicit,
    hasComment: false,
    isTranslated: false,
    hasParentOrChildren: false,
    source: PostSource.none(),
    score: e.likes ?? 0,
    duration: e.duration ?? 0,
    fileSize: 0,
    format: isVideo ? 'mp4' : 'jpg',
    hasSound: isVideo ? true : null,
    height: e.height ?? 0,
    md5: '',
    videoThumbnailUrl: thumbnail,
    videoUrl: isVideo ? original : '',
    width: e.width ?? 0,
    createdAt: DateTime.tryParse(e.posted ?? e.created ?? ''),
    uploaderId: e.uploaderId,
    uploaderName: null,
    metadata: metadata,
  );
}
