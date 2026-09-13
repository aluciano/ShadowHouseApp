// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import '../models/app_settings.dart';
import 'local_app_settings_store_base.dart';

class _WebLocalAppSettingsStore implements LocalAppSettingsStore {
  static const _storageKey = 'shadow_house_app_settings';

  @override
  Future<AppSettings> load() async {
    final content = html.window.localStorage[_storageKey];

    if (content == null || content.trim().isEmpty) {
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
    html.window.localStorage[_storageKey] = jsonEncode(settings.toJson());
  }
}

LocalAppSettingsStore createLocalAppSettingsStoreImpl() =>
    _WebLocalAppSettingsStore();
