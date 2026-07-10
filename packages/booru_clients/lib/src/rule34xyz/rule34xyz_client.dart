// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'types/types.dart';

/// File format ids -> file name suffixes on the CDN.
const kRule34XyzFileSuffixes = <String, String>{
  '1': 'raw',
  '10': 'pic.jpg',
  '11': 'pic256.jpg',
  '12': 'pic256ex.jpg',
  '13': 'picpreview.jpg',
  '14': 'picsmall.jpg',
  '30': 'picavif.avif',
  '31': 'pic256avif.avif',
  '32': 'pic256exavif.avif',
  '33': 'picpreviewavif.avif',
  '34': 'small.avif',
  '100': 'mov.mp4',
  '101': 'mov256.mp4',
  '102': 'mov256ex.mp4',
  '111': '360.mp4',
  '112': 'mov480.mp4',
  '113': 'mov720.mp4',
  '114': '1080.mp4',
};

const _kCdnStorageId = 2;
const _kCdnBaseUrl = 'https://rule34xyz.b-cdn.net';

class Rule34XyzClient {
  Rule34XyzClient({
    required String baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)),
       _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<Rule34XyzPostListDto> getPosts({
    List<String>? tags,
    int page = 1,
    int? limit,
  }) async {
    final includeTags = <String>[];
    final excludeTags = <String>[];

    for (final tag in tags ?? <String>[]) {
      // The site uses spaces inside tag names.
      final normalized = tag.replaceAll('_', ' ').trim();
      if (normalized.isEmpty) continue;

      if (normalized.startsWith('-')) {
        excludeTags.add(normalized.substring(1).trim());
      } else {
        includeTags.add(normalized);
      }
    }

    final take = limit ?? 30;

    final response = await _dio.post(
      '/api/v2/post/search/root',
      data: {
        'includeTags': includeTags,
        if (excludeTags.isNotEmpty) 'excludeTags': excludeTags,
        'sortBy': 0,
        'take': take,
        'skip': (page - 1) * take,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    return switch (response.data) {
      final Map<String, dynamic> json => Rule34XyzPostListDto.fromJson(json),
      _ => const Rule34XyzPostListDto(items: []),
    };
  }

  Future<Rule34XyzPostDto?> getPost({required int id}) async {
    final response = await _dio.get('/api/v2/post/$id');

    return switch (response.data) {
      final Map<String, dynamic> json => Rule34XyzPostDto.fromJson(json),
      _ => null,
    };
  }

  Future<List<Rule34XyzTagDto>> getAutocomplete({
    required String query,
    int limit = 20,
  }) async {
    final sanitized = query.replaceAll('_', ' ').trim();
    if (sanitized.isEmpty) return [];

    final response = await _dio.get(
      '/api/v2/tag/search/${Uri.encodeComponent(sanitized)}',
      queryParameters: {'take': limit},
    );

    return switch (response.data) {
      final List<dynamic> list =>
        list
            .whereType<Map<String, dynamic>>()
            .map(Rule34XyzTagDto.fromJson)
            .toList(),
      _ => const [],
    };
  }

  /// Builds a direct file URL for the given file format id, preferring the
  /// CDN storage when the file is available there.
  String? buildFileUrl(Rule34XyzPostDto post, String formatId) {
    final id = post.id;
    final storages = post.files?[formatId];

    if (id == null || storages == null || storages.isEmpty) return null;

    final suffix = kRule34XyzFileSuffixes[formatId];
    if (suffix == null) return null;

    final host = storages.contains(_kCdnStorageId)
        ? _kCdnBaseUrl
        : _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;

    final prefix = id ~/ 1000;

    return '$host/posts/$prefix/$id/$id.$suffix';
  }

  /// First available file URL among [formatIds], in order of preference.
  String? firstFileUrl(Rule34XyzPostDto post, List<String> formatIds) {
    for (final formatId in formatIds) {
      final url = buildFileUrl(post, formatId);
      if (url != null) return url;
    }

    return null;
  }
}
