import 'dart:io';

import 'package:flutter/services.dart';

class IosSoundItem {
  const IosSoundItem({required this.path, required this.title});

  final String path;
  final String title;

  String get storedValue => 'ios_sound:$path|$title';
}

/// osmWashabeの`IosSoundService`を移植。端末内蔵の着信音ファイル
/// （/System/Library/Ringtones 等）を列挙・再生する。
abstract final class IosSoundService {
  static const _channel = MethodChannel(
    'com.osamushikubo.osm_genki/ios_sounds',
  );

  static bool get isSupported => Platform.isIOS;

  static IosSoundItem? fromStoredValue(String value) {
    if (!value.startsWith('ios_sound:')) return null;
    final rest = value.substring('ios_sound:'.length);
    final sep = rest.indexOf('|');
    if (sep < 0) return IosSoundItem(path: rest, title: rest);
    return IosSoundItem(
      path: rest.substring(0, sep),
      title: rest.substring(sep + 1),
    );
  }

  static Future<List<IosSoundItem>> getSounds() async {
    if (!isSupported) return [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getSounds');
      if (raw == null) return [];
      return raw.whereType<Map<Object?, Object?>>().map((m) {
        return IosSoundItem(
          path: m['path']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> play(String path) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('play', path);
    } catch (_) {}
  }

  static Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
