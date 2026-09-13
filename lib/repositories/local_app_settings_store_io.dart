import 'dart:convert';
import 'dart:io';

import '../models/app_settings.dart';
import 'local_app_settings_store_base.dart';

class _FileLocalAppSettingsStore implements LocalAppSettingsStore {
  static const _fileName = 'shadow_house_app_settings.json';

  File get _file =>
      File('${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName');

  @override
  Future<AppSettings> load() async {
    if (!await _file.exists()) {
      return const AppSettings();
    }

    final content = await _file.readAsString();

    if (content.trim().isEmpty) {
      return const AppSettings();
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      return const AppSettings();
    }

    return AppSettings.fromJson(decoded);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _file.writeAsString(jsonEncode(settings.toJson()));
  }
}

LocalAppSettingsStore createLocalAppSettingsStoreImpl() =>
    _FileLocalAppSettingsStore();
