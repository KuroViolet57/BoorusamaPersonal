// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:boorusama/core/boorus/booru/types.dart';
import 'package:boorusama/core/search/queries/or_operator.dart';

void main() {
  group('OR group expansion keeps AND semantics between groups', () {
    final cases = [
      (
        type: BooruType.danbooru,
        input: ['animated|video', 'dog'],
        expected: ['( animated or video )', 'dog'],
      ),
      (
        type: BooruType.danbooru,
        input: ['animated|video', 'dog|cat'],
        expected: ['( animated or video )', '( dog or cat )'],
      ),
      (
        type: BooruType.gelbooru,
        input: ['animated|video', 'dog'],
        expected: ['( animated ~ video )', 'dog'],
      ),
      (
        type: BooruType.gelbooruV2,
        input: ['animated|video|webm', 'dog|cat'],
        expected: ['( animated ~ video ~ webm )', '( dog ~ cat )'],
      ),
      (
        type: BooruType.e621,
        input: ['animated|webm', 'dog'],
        expected: ['~animated', '~webm', 'dog'],
      ),
      (
        type: BooruType.philomena,
        input: ['animated|webm', 'safe'],
        expected: ['(animated || webm)', 'safe'],
      ),
      (
        type: BooruType.szurubooru,
        input: ['cat|dog', 'cute'],
        expected: ['cat,dog', 'cute'],
      ),
      // No OR support: degrade to the first tag, never a merged OR soup.
      (
        type: BooruType.shimmie2,
        input: ['animated|webm', 'dog'],
        expected: ['animated', 'dog'],
      ),
      (
        type: BooruType.moebooru,
        input: ['animated|video'],
        expected: ['animated'],
      ),
    ];

    for (final c in cases) {
      test(
        '${c.type.name}: ${c.input.join(' ')} -> ${c.expected.join(' ')}',
        () {
          expect(expandOrGroups(c.input, c.type), c.expected);
        },
      );
    }
  });

  group('single-group sites degrade extra groups safely', () {
    test(
      'second group on e621 falls back to its first tag to avoid one giant OR',
      () {
        expect(
          expandOrGroups(['animated|video', 'dog|cat'], BooruType.e621),
          ['~animated', '~video', 'dog'],
        );
      },
    );
  });

  group('non-group tokens pass through', () {
    final cases = [
      (input: ['plain_tag', '-excluded'], name: 'plain and negated tags'),
      (input: ['-video|animated'], name: 'negated group'),
      (input: ['rating:safe'], name: 'metatags'),
    ];

    for (final c in cases) {
      test('${c.name} are untouched', () {
        expect(
          expandOrGroups(c.input, BooruType.danbooru),
          c.input,
        );
      });
    }
  });
}
