// Project imports:
import '../../boorus/booru/types.dart';

/// How a booru expresses "tag A OR tag B" natively.
enum OrQueryCapability {
  /// Danbooru 2.x: `( a or b )`, multiple groups supported.
  parenOr,

  /// Gelbooru 0.2.x: `( a ~ b )`, multiple groups supported.
  parenTilde,

  /// Danbooru 1.x style (e621, Sankaku): `~a ~b`. All `~` tags form a single
  /// OR group, so only one group per query is expressible.
  tildePrefix,

  /// Philomena: `(a || b)`, multiple groups supported.
  doublePipe,

  /// Szurubooru: `a,b` value alternation inside a single token.
  commaJoin,

  /// No OR support; fall back to the first tag of the group.
  unsupported,
}

OrQueryCapability orQueryCapabilityOf(BooruType type) => switch (type) {
  BooruType.danbooru => OrQueryCapability.parenOr,
  BooruType.gelbooru || BooruType.gelbooruV2 => OrQueryCapability.parenTilde,
  BooruType.e621 || BooruType.sankaku => OrQueryCapability.tildePrefix,
  BooruType.philomena => OrQueryCapability.doublePipe,
  BooruType.szurubooru => OrQueryCapability.commaJoin,
  _ => OrQueryCapability.unsupported,
};

/// Expands local OR groups (`tag1|tag2`, pipes with no spaces) into the
/// booru's native OR form. Groups keep AND semantics between each other:
/// `animated|video dog|cat` means (animated OR video) AND (dog OR cat).
///
/// On sites that can only express a single OR group (`~` prefix style), the
/// first group is translated and later groups degrade to their first tag so
/// results never include false positives.
List<String> expandOrGroups(List<String> tags, BooruType booruType) {
  final capability = orQueryCapabilityOf(booruType);
  final result = <String>[];
  var tildeGroupUsed = false;

  for (final tag in tags) {
    if (!_isOrGroup(tag)) {
      result.add(tag);
      continue;
    }

    final parts = tag.split('|').where((e) => e.isNotEmpty).toList();

    if (parts.length < 2) {
      result.addAll(parts);
      continue;
    }

    switch (capability) {
      case OrQueryCapability.parenOr:
        result.add('( ${parts.join(' or ')} )');
      case OrQueryCapability.parenTilde:
        result.add('( ${parts.join(' ~ ')} )');
      case OrQueryCapability.doublePipe:
        result.add('(${parts.join(' || ')})');
      case OrQueryCapability.commaJoin:
        result.add(parts.join(','));
      case OrQueryCapability.tildePrefix:
        if (!tildeGroupUsed) {
          tildeGroupUsed = true;
          result.addAll(parts.map((e) => '~$e'));
        } else {
          result.add(parts.first);
        }
      case OrQueryCapability.unsupported:
        result.add(parts.first);
    }
  }

  return result;
}

bool _isOrGroup(String tag) {
  if (!tag.contains('|')) return false;
  // Negated groups and metatag-style tokens are passed through untouched.
  if (tag.startsWith('-')) return false;

  return true;
}
