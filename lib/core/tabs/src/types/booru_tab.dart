// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import '../../../search/selected_tags/types.dart';

class BooruTab extends Equatable {
  const BooruTab({
    required this.id,
    required this.tags,
    this.title,
  });

  factory BooruTab.fromTagSet({
    required String id,
    required SearchTagSet tagSet,
    String? title,
  }) => BooruTab(
    id: id,
    tags: List.unmodifiable(tagSet.list),
    title: title,
  );

  factory BooruTab.fromJson(Map<String, dynamic> json) => BooruTab(
    id: json['id'] as String,
    tags: List<String>.unmodifiable(
      (json['tags'] as List).map((e) => e as String),
    ),
    title: json['title'] as String?,
  );

  final String id;
  final List<String> tags;
  final String? title;

  String get displayTitle => switch ((title, tags)) {
    (final t?, _) when t.isNotEmpty => t,
    (_, []) => 'all',
    _ => tags.join(' '),
  };

  SearchTagSet toTagSet() => SearchTagSet.fromList(tags);

  BooruTab copyWith({
    List<String>? tags,
    String? title,
  }) => BooruTab(
    id: id,
    tags: tags ?? this.tags,
    title: title ?? this.title,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tags': tags,
    if (title != null) 'title': title,
  };

  @override
  List<Object?> get props => [id, tags, title];
}
