import 'notifiers/app_settings.dart';
import 'services/cloud_sync/cloud_sync_service.dart';
export 'notifiers/app_appearance.dart';
export 'notifiers/app_settings.dart';

/// osmWashabeと同じ、アプリ全体で共有するグローバルな設定インスタンス。
late AppSettings appSettings;

/// iCloud同期（iOSのみ。Androidでは作らず、設定にも出さない）。
CloudSyncService? cloudSync;
