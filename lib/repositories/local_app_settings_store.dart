import 'local_app_settings_store_base.dart';
import 'local_app_settings_store_stub.dart'
    if (dart.library.io) 'local_app_settings_store_io.dart'
    if (dart.library.html) 'local_app_settings_store_web.dart';

LocalAppSettingsStore createLocalAppSettingsStore() =>
    createLocalAppSettingsStoreImpl();
