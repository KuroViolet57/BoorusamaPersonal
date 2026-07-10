class Rule34XyzTagDto {
  const Rule34XyzTagDto({
    this.id,
    this.value,
    this.count,
    this.type,
  });

  factory Rule34XyzTagDto.fromJson(Map<String, dynamic> json) {
    return Rule34XyzTagDto(
      id: json['id'] as int?,
      value: json['value'] as String?,
      count: json['count'] as int?,
      type: json['type'] as int?,
    );
  }

  final int? id;
  final String? value;
  final int? count;
  final int? type;
}

class Rule34XyzPostDto {
  const Rule34XyzPostDto({
    this.id,
    this.created,
    this.posted,
    this.likes,
    this.views,
    this.type,
    this.status,
    this.uploaderId,
    this.width,
    this.height,
    this.duration,
    this.files,
    this.tags,
  });

  factory Rule34XyzPostDto.fromJson(Map<String, dynamic> json) {
    return Rule34XyzPostDto(
      id: json['id'] as int?,
      created: json['created'] as String?,
      posted: json['posted'] as String?,
      likes: json['likes'] as int?,
      views: json['views'] as int?,
      type: json['type'] as int?,
      status: json['status'] as int?,
      uploaderId: json['uploaderId'] as int?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      files: switch (json['files']) {
        final Map<String, dynamic> map => {
          for (final entry in map.entries)
            if (entry.value case final List<dynamic> storages)
              entry.key: storages.whereType<int>().toList(),
        },
        _ => null,
      },
      tags: switch (json['tags']) {
        final List<dynamic> list =>
          list
              .whereType<Map<String, dynamic>>()
              .map(Rule34XyzTagDto.fromJson)
              .toList(),
        _ => null,
      },
    );
  }

  final int? id;
  final String? created;
  final String? posted;
  final int? likes;
  final int? views;
  final int? type;
  final int? status;
  final int? uploaderId;
  final double? width;
  final double? height;
  final double? duration;

  /// File format id -> list of storage ids where the file is available.
  final Map<String, List<int>>? files;
  final List<Rule34XyzTagDto>? tags;
}

class Rule34XyzPostListDto {
  const Rule34XyzPostListDto({
    required this.items,
    this.cursor,
  });

  factory Rule34XyzPostListDto.fromJson(Map<String, dynamic> json) {
    return Rule34XyzPostListDto(
      items: switch (json['items']) {
        final List<dynamic> list =>
          list
              .whereType<Map<String, dynamic>>()
              .map(Rule34XyzPostDto.fromJson)
              .toList(),
        _ => const [],
      },
      cursor: json['cursor']?.toString(),
    );
  }

  final List<Rule34XyzPostDto> items;
  final String? cursor;
}
