// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Project imports:
import '../../../../configs/config/providers.dart';
import '../../../../configs/config/types.dart';
import '../../../../preview/preview.dart';
import '../../../../tabs/tabs.dart';
import '../../../../tags/categories/providers.dart';
import '../../../../themes/colors/providers.dart';
import '../../../../themes/colors/types.dart';
import 'raw_tag_chip.dart';

class TagChip extends ConsumerWidget {
  const TagChip({
    required this.text,
    required this.auth,
    super.key,
    this.category,
    this.postCount,
    this.onTap,
    this.onLongPress,
    this.maxWidth,
    this.fallbackColor,
    this.colorOverride,
    this.transformText = false,
    this.showPostCount = true,
    this.enableTabActions = true,
  });

  final String text;
  final String? category;
  final int? postCount;
  final BooruConfigAuth auth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? maxWidth;
  final Color? fallbackColor;
  final Color? colorOverride;
  final bool transformText;
  final bool showPostCount;
  final bool enableTabActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = _resolveColors(ref);
    final displayText = transformText
        ? text.toLowerCase().replaceAll('_', ' ')
        : text;
    final loginDetails = ref.watch(booruLoginDetailsProvider(auth));

    final subtitle = _buildSubtitle(loginDetails);

    return Builder(
      builder: (innerContext) => RawTagChip(
        text: displayText,
        subtitle: subtitle,
        onTap: onTap,
        onLongPress: onLongPress ??
            (enableTabActions
                ? () => showTabActionsForTag(
                      innerContext,
                      ref,
                      tag: text,
                      onPreview: () =>
                          openTagPreview(ref, tag: text, fromAuth: auth),
                    )
                : null),
        maxWidth: maxWidth,
        backgroundColor: colors?.backgroundColor,
        foregroundColor: colors?.foregroundColor,
        borderColor: colors?.borderColor,
      ),
    );
  }

  ChipColors? _resolveColors(WidgetRef ref) {
    // Priority: colorOverride → category → fallbackColor
    if (colorOverride != null) {
      return ref.watch(booruChipColorsProvider).fromColor(colorOverride);
    }

    if (category != null) {
      return ref.watch(
        chipColorsFromTagStringProvider((auth, category!)),
      );
    }

    return ref.watch(booruChipColorsProvider).fromColor(fallbackColor);
  }

  String? _buildSubtitle(BooruLoginDetails loginDetails) {
    if (!showPostCount ||
        loginDetails.hasStrictSFW ||
        postCount == null ||
        postCount! <= 0) {
      return null;
    }

    return NumberFormat.compact().format(postCount);
  }
}

class AutoCategoryTagChip extends ConsumerWidget {
  const AutoCategoryTagChip({
    required this.text,
    required this.auth,
    super.key,
    this.onTap,
    this.onLongPress,
    this.maxWidth,
    this.fallbackColor,
    this.colorOverride,
    this.transformText = true,
  });

  final String text;
  final BooruConfigAuth auth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? maxWidth;
  final Color? fallbackColor;
  final Color? colorOverride;
  final bool transformText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(booruTagTypeProvider((auth, text))).valueOrNull;

    return TagChip(
      text: text,
      auth: auth,
      category: category,
      onTap: onTap,
      onLongPress: onLongPress,
      maxWidth: maxWidth,
      fallbackColor: fallbackColor,
      colorOverride: colorOverride,
      transformText: transformText,
      showPostCount: false, // Auto category lookup doesn't provide post count
    );
  }
}
