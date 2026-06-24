// Flutter imports:
import 'package:flutter/material.dart';

/// IndexedStack that builds only "alive" children fully; others render a
/// lightweight placeholder. IndexedStack already preserves widget state of
/// all children that ARE built, so re-selecting an alive index restores its
/// scroll/fetch state without any extra plumbing.
class LazyIndexedStack extends StatelessWidget {
  const LazyIndexedStack({
    required this.index,
    required this.itemCount,
    required this.aliveIndices,
    required this.aliveBuilder,
    required this.placeholderBuilder,
    super.key,
  });

  final int index;
  final int itemCount;
  final Set<int> aliveIndices;
  final Widget Function(BuildContext context, int index) aliveBuilder;
  final Widget Function(BuildContext context, int index) placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final safeIndex = index.clamp(0, itemCount - 1);

    return IndexedStack(
      index: safeIndex,
      children: List.generate(itemCount, (i) {
        final isAlive = aliveIndices.contains(i) || i == safeIndex;
        return KeyedSubtree(
          key: ValueKey('lazy_stack_slot_$i'),
          child: isAlive
              ? aliveBuilder(context, i)
              : placeholderBuilder(context, i),
        );
      }),
    );
  }
}
