import '../models/app_settings.dart';

abstract class LocalAppSettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
