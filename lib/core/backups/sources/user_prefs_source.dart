// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../foundation/info/package_info.dart';
import '../../cache/providers.dart';
import '../../search_tabs/providers.dart';
import '../../tags/preview/widgets.dart';
import '../utils/json_handler.dart';
import '../widgets/backup_restore_tile.dart';
import 'json_source.dart';

const kUserPrefsBackupVersion = 1;

const _kBackupKeys = [
  kSearchTabsDataKey,
  kTagPreviewGeometryKey,
];

class UserPrefsBackupSource extends JsonBackupSource<Map<String, dynamic>> {
  UserPrefsBackupSource(Ref ref)
    : super(
        id: 'user_prefs',
        priority: 4,
        version: kUserPrefsBackupVersion,
        appVersion: ref.read(appVersionProvider),
        dataGetter: () async {
          final box = ref.read(miscDataBoxProvider);

          return {
            for (final key in _kBackupKeys)
              if (box.get(key) case final String value when value.isNotEmpty)
                key: value,
          };
        },
        executor: (data, _) async {
          final box = ref.read(miscDataBoxProvider);

          for (final entry in data.entries) {
            if (entry.value case final String value) {
              await box.put(entry.key, value);
            }
          }

          ref.invalidate(searchTabsProvider);
        },
        handler: SingleHandler<Map<String, dynamic>>(
          parser: (json) => json,
          encoder: (data) => data,
        ),
        ref: ref,
      );

  @override
  String get displayName => 'Search tabs & preview window';

  @override
  Widget buildTile(BuildContext context) {
    return DefaultBackupTile(
      source: this,
      title: 'Search tabs & preview window',
      icon: Symbols.tab,
    );
  }
}
