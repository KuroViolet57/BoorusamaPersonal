// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../routes/routes.dart';

/// Shows a small popup with tab-related actions for a single [tag].
///
/// Designed to be invoked from a long-press handler on a tag chip or any
/// other widget representing one tag.
Future<void> showTabActionsForTag(
  BuildContext context,
  WidgetRef ref, {
  required String tag,
  void Function()? onPreview,
}) async {
  final renderBox = context.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  final offset = renderBox != null && overlay != null
      ? renderBox.localToGlobal(Offset.zero, ancestor: overlay)
      : Offset.zero;
  final size = renderBox?.size ?? Size.zero;

  final selected = await showMenu<_TabAction>(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height,
      offset.dx + size.width,
      offset.dy,
    ),
    items: [
      const PopupMenuItem(
        value: _TabAction.newTab,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Symbols.add),
          title: Text('Open in new tab'),
        ),
      ),
      const PopupMenuItem(
        value: _TabAction.addToCurrent,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Symbols.playlist_add),
          title: Text('Add to current tab'),
        ),
      ),
      if (onPreview != null)
        const PopupMenuItem(
          value: _TabAction.preview,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Symbols.preview),
            title: Text('Preview'),
          ),
        ),
    ],
  );

  switch (selected) {
    case _TabAction.newTab:
      openInNewTab(ref, tags: [tag], title: tag);
    case _TabAction.addToCurrent:
      addToCurrentTab(ref, tag: tag);
    case _TabAction.preview:
      onPreview?.call();
    case null:
      break;
  }
}

enum _TabAction { newTab, addToCurrent, preview }
