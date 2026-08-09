import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/android_ringtone_service.dart';
import '../services/ios_sound_service.dart';
import '../services/timer_alert.dart';
import '../services/timer_completion_sound_catalog.dart';
import '../theme/app_colors.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/swipe_down_to_dismiss.dart';

/// osmWashabeの`TimerSoundPickerView`を移植。カウントダウンタイマー終了チャイムを
/// 選ぶ設定画面（iOS: システムサウンドカタログ＋端末の着信音／Android: 端末の通知音）。
class TimerSoundPickerPage extends StatefulWidget {
  const TimerSoundPickerPage({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<TimerSoundPickerPage> createState() => _TimerSoundPickerPageState();
}

class _TimerSoundPickerPageState extends State<TimerSoundPickerPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwipeDownToDismiss(
      scrollController: _scrollController,
      child: GenkiSubpageScaffold(
        title: 'タイマー音'.tr(widget.languageCode),
        body: Platform.isAndroid
            ? _AndroidSoundPicker(
                lang: widget.languageCode,
                scrollController: _scrollController,
              )
            : _IosSoundPicker(
                lang: widget.languageCode,
                scrollController: _scrollController,
              ),
      ),
    );
  }
}

// ─── iOS ──────────────────────────────────────────────────────────────────────

class _IosSoundPicker extends StatefulWidget {
  const _IosSoundPicker({required this.lang, required this.scrollController});

  final String lang;
  final ScrollController scrollController;

  @override
  State<_IosSoundPicker> createState() => _IosSoundPickerState();
}

class _IosSoundPickerState extends State<_IosSoundPicker> {
  List<IosSoundItem> _ringtones = [];

  @override
  void initState() {
    super.initState();
    _loadRingtones();
  }

  Future<void> _loadRingtones() async {
    final items = await IosSoundService.getSounds();
    if (mounted) setState(() => _ringtones = items);
  }

  @override
  void dispose() {
    IosSoundService.stop();
    super.dispose();
  }

  bool _isCatalogSelected(TimerSoundItem item) =>
      appSettings.completionSound ==
      TimerCompletionSoundCatalog.normalizedStoredValue(item.storedValue);

  bool _isRingtoneSelected(IosSoundItem item) =>
      appSettings.completionSound == item.storedValue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      children: [
        for (final item in TimerCompletionSoundCatalog.allItems)
          ListTile(
            title: Text(item.nameKey.tr(widget.lang)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.playable)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => TimerAlert.previewSound(item.storedValue),
                  ),
                if (_isCatalogSelected(item))
                  Icon(Icons.check, color: AppColors.current.accentColor),
              ],
            ),
            onTap: () => setState(() {
              appSettings.completionSound = item.storedValue;
            }),
          ),
        for (final item in _ringtones)
          ListTile(
            title: Text(item.title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => IosSoundService.play(item.path),
                ),
                if (_isRingtoneSelected(item))
                  Icon(Icons.check, color: AppColors.current.accentColor),
              ],
            ),
            onTap: () => setState(() {
              appSettings.completionSound = item.storedValue;
            }),
          ),
      ],
    );
  }
}

// ─── Android ──────────────────────────────────────────────────────────────────

class _AndroidSoundPicker extends StatefulWidget {
  const _AndroidSoundPicker({
    required this.lang,
    required this.scrollController,
  });

  final String lang;
  final ScrollController scrollController;

  @override
  State<_AndroidSoundPicker> createState() => _AndroidSoundPickerState();
}

class _AndroidSoundPickerState extends State<_AndroidSoundPicker> {
  List<AndroidRingtoneItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AndroidRingtoneService.getRingtones();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    AndroidRingtoneService.stopRingtone();
    super.dispose();
  }

  bool _isSelected(AndroidRingtoneItem item) =>
      appSettings.completionSound == item.storedValue;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(child: Text('利用できる音がありません'.tr(widget.lang)));
    }
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return ListTile(
          title: Text(item.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => AndroidRingtoneService.playRingtone(item.uri),
              ),
              if (_isSelected(item))
                Icon(Icons.check, color: AppColors.current.accentColor),
            ],
          ),
          onTap: () {
            appSettings.completionSound = item.storedValue;
            setState(() {});
          },
        );
      },
    );
  }
}
