import '../models/app_settings.dart';
import 'local_app_settings_store_base.dart';

class _NoopLocalAppSettingsStore implements LocalAppSettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

LocalAppSettingsStore createLocalAppSettingsStoreImpl() =>
    _NoopLocalAppSettingsStore();
