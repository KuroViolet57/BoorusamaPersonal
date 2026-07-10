// Package imports:
import 'package:booru_clients/rule34xyz.dart';

// Project imports:
import '../../../core/tags/autocompletes/types.dart';
import '../../../core/tags/categories/types.dart';
import '../../../core/tags/tag/types.dart';

AutocompleteData tagDtoToAutocompleteData(Rule34XyzTagDto e) {
  final label = e.value ?? '';

  return AutocompleteData(
    label: label,
    value: label.replaceAll(' ', '_'),
    postCount: e.count,
    category: tagTypeToCategoryName(e.type),
  );
}

Tag tagDtoToTag(Rule34XyzTagDto e) {
  return Tag(
    name: (e.value ?? '').replaceAll(' ', '_'),
    category: switch (e.type) {
      2 => TagCategory.copyright(),
      4 => TagCategory.character(),
      8 => TagCategory.artist(),
      32 => TagCategory.meta(),
      _ => TagCategory.general(),
    },
    postCount: e.count ?? 0,
  );
}

String tagTypeToCategoryName(int? type) => switch (type) {
  2 => 'copyright',
  4 => 'character',
  8 => 'artist',
  32 => 'meta',
  _ => 'general',
};
