import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../models/appearance_models.dart';
import '../services/diary_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/diary_card.dart';
import '../widgets/genki_frame_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

/// 1日分の元気度データ（カレンダー表示用）。
/// 同日の複数記録をまとめる際に平均を使う。
class _DailyGenki {
  _DailyGenki({required this.day, required this.entries});

  final DateTime day;
  final List<DiaryEntry> entries;

  int get averageScore =>
      (entries.map((e) => e.genkiScore).reduce((a, b) => a + b) /
              entries.length)
          .round();

  /// 日本語評点が記録されているエントリだけで平均する。1件も無ければnull。
  double? get averageJapaneseLevel {
    final levels = entries.map((e) => e.japaneseLevel).whereType<int>();
    if (levels.isEmpty) return null;
    return levels.reduce((a, b) => a + b) / levels.length;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<DiaryEntry>> _entriesFuture;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  /// 範囲切り替え・日記更新など、外部要因でグラフを最新表示に戻したい時に
  /// 増やすカウンタ。グラフのスクロール位置自体は[_GenkiLineChart]内部で
  /// 保持しているので、これが変わった時だけ最新（右端）に戻す。
  int _chartResetTick = 0;

  @override
  void initState() {
    super.initState();
    _entriesFuture = DiaryStorage.loadAll();
    appSettings.addListener(_onSettingsChanged);
    DiaryStorage.changes.addListener(_onDiaryChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    DiaryStorage.changes.removeListener(_onDiaryChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  /// 会話が終わって日記が保存されたら、表示中でも最新の内容に更新する。
  void _onDiaryChanged() {
    setState(() {
      _entriesFuture = DiaryStorage.loadAll();
      _selectedDay = null;
      _chartResetTick++;
    });
  }

  Map<String, _DailyGenki> _groupByDay(List<DiaryEntry> entries) {
    final grouped = <String, List<DiaryEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.dateKey, () => []).add(entry);
    }
    return grouped.map((key, list) {
      final first = list.first.date;
      final day = DateTime(first.year, first.month, first.day);
      return MapEntry(key, _DailyGenki(day: day, entries: list));
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final scene = appAppearance.sceneColor;
    final fg = appAppearance.foregroundOn(scene);
    final frameStyle = appAppearance.resolvedFrameStyle();
    return FutureBuilder<List<DiaryEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator(color: fg));
        }

        final byDay = _groupByDay(snapshot.data ?? const []);
        final latestDay = byDay.isEmpty
            ? DateTime.now()
            : byDay.values
                  .map((d) => d.day)
                  .reduce((a, b) => a.isAfter(b) ? a : b);
        final earliestDay = byDay.isEmpty
            ? latestDay
            : byDay.values
                  .map((d) => d.day)
                  .reduce((a, b) => a.isBefore(b) ? a : b);
        final selectedEntries = _selectedDay == null
            ? const <DiaryEntry>[]
            : byDay[DiaryStorage.dateKeyFor(_selectedDay!)]?.entries ??
                  const <DiaryEntry>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'スコアの推移'.tr(lang),
                      style: TextStyle(
                        color: fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _GenkiLineChart(
                entries: snapshot.data ?? const [],
                baseDay: latestDay,
                earliestDay: earliestDay,
                resetTick: _chartResetTick,
                frameStyle: frameStyle,
              ),
              const SizedBox(height: 32),
              _MiniCalendar(
                focusedMonth: _focusedMonth,
                byDay: byDay,
                selectedDay: _selectedDay,
                frameStyle: frameStyle,
                onMonthChanged: (month) {
                  setState(() {
                    _focusedMonth = month;
                    _selectedDay = null;
                  });
                },
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay =
                        (_selectedDay != null && _isSameDay(_selectedDay!, day))
                        ? null
                        : day;
                  });
                },
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
                child: selectedEntries.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('empty'))
                    : Column(
                        key: ValueKey(_selectedDay),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in selectedEntries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DiaryCard(entry: entry),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GenkiChartLayout {
  const _GenkiChartLayout({
    required this.genkiSpots,
    required this.japaneseSpots,
    required this.axisAnchors,
    required this.maxX,
    required this.earliestDataX,
    required this.latestDataX,
    required this.showYearOnAxis,
  });

  /// 元気度（0〜10）の折れ線用の点。
  final List<FlSpot> genkiSpots;

  /// 日本語評点（1〜10）の折れ線用の点。
  final List<FlSpot> japaneseSpots;

  final List<DateTime> axisAnchors;
  final double maxX;

  /// いちばん古い記録の X 座標（日単位・小数あり）。
  final double earliestDataX;

  /// いちばん新しい記録の X 座標（日単位・小数あり）。
  final double latestDataX;
  final bool showYearOnAxis;
}

class _GenkiLineChart extends StatefulWidget {
  const _GenkiLineChart({
    required this.entries,
    required this.baseDay,
    required this.earliestDay,
    required this.resetTick,
    required this.frameStyle,
  });

  final List<DiaryEntry> entries;

  /// 最新の日（グラフの右端に来る基準日）。
  final DateTime baseDay;

  /// データ全体でいちばん古い日（連続スクロールの左端）。
  final DateTime earliestDay;

  /// 範囲切り替え・日記更新などで、表示位置を最新（右端）に戻したい時に
  /// 増える値。[_GenkiLineChartState]はこれが変わった時だけ表示位置を
  /// リセットする（スワイプ操作自体では動かない）。
  final int resetTick;
  final FrameResolvedStyle frameStyle;

  static const _leftAxisWidth = 30.0;
  static const _bottomAxisHeight = 32.0;
  static const _minimumAxisDays = 30;
  static const _futureAxisDays = 14;

  /// 最古〜最新の全期間ぶんを1本の連続したレイアウトにする。
  static _GenkiChartLayout _fullLayout(
    List<DiaryEntry> entries,
    DateTime earliestDay,
    DateTime latestDay,
  ) {
    final minimumStart = latestDay.subtract(
      const Duration(days: _minimumAxisDays - 1),
    );
    final chartStart = earliestDay.isBefore(minimumStart)
        ? earliestDay
        : minimumStart;
    final chartEnd = latestDay.add(const Duration(days: _futureAxisDays));
    final spanDays = chartEnd.difference(chartStart).inDays + 1;
    final days = List.generate(
      spanDays,
      (i) => chartStart.add(Duration(days: i)),
    );
    final genkiSpots = <FlSpot>[];
    final japaneseSpots = <FlSpot>[];
    final sortedEntries = [...entries]
      ..sort((a, b) => a.date.compareTo(b.date));
    final duplicateCounter = <String, int>{};
    for (final entry in sortedEntries) {
      final entryDay = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final dayIndex = entryDay.difference(chartStart).inDays;
      if (dayIndex < 0 || dayIndex >= days.length) continue;

      // 同日の複数記録は平均化せず、時刻ベースの小さな差で個別に打点する。
      final recorded = entry.recordedAt ?? entry.date;
      final secondsOfDay =
          recorded.hour * 3600 + recorded.minute * 60 + recorded.second;
      final baseOffset = (secondsOfDay / Duration.secondsPerDay).clamp(
        0.0,
        0.9999,
      );

      // 同秒に複数件ある場合も重ならないよう、ごく小さいオフセットを加える。
      final sameSecondKey = '${entryDay.toIso8601String()}-$secondsOfDay';
      final sameSecondIndex = duplicateCounter.update(
        sameSecondKey,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final duplicateOffset = (sameSecondIndex * 0.0002).clamp(0.0, 0.0008);
      final x = (dayIndex + baseOffset + duplicateOffset).clamp(
        0.0,
        (days.length - 1).toDouble(),
      );

      genkiSpots.add(FlSpot(x, entry.genkiScore.toDouble()));
      if (entry.japaneseLevel != null) {
        japaneseSpots.add(FlSpot(x, entry.japaneseLevel!.toDouble()));
      }
    }
    final fallbackLatestX = (days.length - 1 - _futureAxisDays)
        .toDouble()
        .clamp(0.0, (days.length - 1).toDouble());
    final earliestDataX = genkiSpots.isEmpty
        ? fallbackLatestX
        : genkiSpots.map((s) => s.x).reduce(min);
    final latestDataX = genkiSpots.isEmpty
        ? fallbackLatestX
        : genkiSpots.map((s) => s.x).reduce(max);
    return _GenkiChartLayout(
      genkiSpots: genkiSpots,
      japaneseSpots: japaneseSpots,
      axisAnchors: days,
      maxX: (days.length - 1).toDouble().clamp(0, double.infinity),
      earliestDataX: earliestDataX,
      latestDataX: latestDataX,
      showYearOnAxis: days.length > 90,
    );
  }

  @override
  State<_GenkiLineChart> createState() => _GenkiLineChartState();
}

class _GenkiLineChartState extends State<_GenkiLineChart> {
  static const _defaultVisibleDays = 14.0;

  /// 初回表示で最新データを置く位置（左端=0、右端=1）。中央やや右 ≒ 62%。
  static const _initialLatestAnchorFraction = 0.62;

  /// ピンチアウト（拡大）の下限。1分ぶんの横軸幅まで寄せられる。
  static const _minVisibleDays = 1 / 1440;

  /// 横軸ラベル同士の最低ピクセル間隔（これより詰めると重なる）。
  static const _minLabelSpacingPx = 56.0;
  double _visibleDays = _defaultVisibleDays;
  double _startX = 0;
  double _gestureStartVisibleDays = _defaultVisibleDays;
  double _gestureStartStartX = 0;
  double _plotWidth = 320;
  bool _viewportInitialized = false;
  bool _scheduledLayoutRefresh = false;
  int _activePointers = 0;

  /// 表示窓 [start, end]（end は start より必ず大きい）。
  ({double start, double end, double span}) _viewportBounds(double maxX) {
    final span = _visibleDays.clamp(
      _minVisibleDays,
      max(_minVisibleDays, maxX),
    );
    var start = _startX.clamp(0.0, max(0.0, maxX - span));
    var end = start + span;
    if (end > maxX) {
      end = maxX;
      start = max(0.0, end - span);
    }
    if (end <= start) {
      end = start + _minVisibleDays;
    }
    return (
      start: start.toDouble(),
      end: end.toDouble(),
      span: (end - start).toDouble(),
    );
  }

  /// 記録が2件以上なら最古〜最新をグラフ幅いっぱいに、1件以下は従来の14日窓。
  void _initializeViewport(_GenkiChartLayout layout) {
    final maxX = layout.maxX;
    if (layout.genkiSpots.length <= 1) {
      _visibleDays = _defaultVisibleDays;
      final span = _visibleDays.clamp(
        _minVisibleDays,
        max(_minVisibleDays, maxX),
      );
      _startX = (layout.latestDataX - span * _initialLatestAnchorFraction)
          .clamp(0.0, max(0.0, maxX - span));
    } else {
      final earliest = layout.earliestDataX;
      final latest = layout.latestDataX;
      final dataSpan = max(latest - earliest, _minVisibleDays);
      _visibleDays = dataSpan;
      _startX = earliest.clamp(0.0, max(0.0, maxX - dataSpan));
    }
    _clampViewport(maxX);
  }

  void _clampViewport(double maxX) {
    final minVisible = _minVisibleDays.clamp(0.0, maxX);
    final maxVisible = max(minVisible, maxX);
    _visibleDays = _visibleDays.clamp(minVisible, maxVisible);
    final maxStart = max(0.0, maxX - _visibleDays);
    _startX = _startX.clamp(0.0, maxStart);
  }

  @override
  void didUpdateWidget(covariant _GenkiLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxX = _GenkiLineChart._fullLayout(
      widget.entries,
      widget.earliestDay,
      widget.baseDay,
    ).maxX;
    _clampViewport(maxX);
    if (widget.resetTick != oldWidget.resetTick) {
      _viewportInitialized = false;
      _scheduledLayoutRefresh = false;
      _clampViewport(maxX);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildZoomableCard();
  }

  Widget _buildZoomableCard() {
    final lang = appSettings.language;
    final fullLayout = _GenkiLineChart._fullLayout(
      widget.entries,
      widget.earliestDay,
      widget.baseDay,
    );
    final lineColor = widget.frameStyle.accentStrip;
    final japaneseLineColor = widget.frameStyle.readablePrimaryText;
    final mutedText = widget.frameStyle.readableSecondaryText;
    final showJapaneseLine = fullLayout.japaneseSpots.isNotEmpty;

    if (fullLayout.genkiSpots.isEmpty) {
      return SizedBox(
        height: 160,
        child: GenkiFrameCard(
          style: widget.frameStyle,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'まだデータがないよ。\n話すとここに元気度が記録されるよ。'.tr(lang),
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText),
              ),
            ),
          ),
        ),
      );
    }

    final maxX = fullLayout.maxX;
    _clampViewport(maxX);

    return SizedBox(
      height: 248,
      child: GenkiFrameCard(
        style: widget.frameStyle,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          children: [
            _ChartLegend(
              genkiColor: lineColor,
              japaneseColor: japaneseLineColor,
              showJapanese: showJapaneseLine,
              mutedText: mutedText,
              lang: lang,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth
                      .clamp(1.0, double.infinity)
                      .toDouble();
                  if (width < 48) {
                    return const SizedBox.shrink();
                  }
                  _plotWidth = width;

                  if (!_viewportInitialized) {
                    _initializeViewport(fullLayout);
                    _viewportInitialized = true;
                    if (!_scheduledLayoutRefresh) {
                      _scheduledLayoutRefresh = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() => _scheduledLayoutRefresh = false);
                      });
                    }
                  }

                  final viewport = _viewportBounds(maxX);
                  final labelInterval = _chartLabelInterval(
                    visibleSpan: viewport.span,
                    plotWidth: _plotWidth,
                  );
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _activePointers++,
                    onPointerUp: (_) =>
                        _activePointers = (_activePointers - 1).clamp(0, 10),
                    onPointerCancel: (_) =>
                        _activePointers = (_activePointers - 1).clamp(0, 10),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (_) {
                        _gestureStartVisibleDays = _visibleDays;
                        _gestureStartStartX = _startX;
                      },
                      onScaleUpdate: (details) {
                        if (_activePointers >= 2) {
                          // scale が 0 付近になると窓幅が暴れてグラフが反転するためクランプする。
                          final scale = details.scale.clamp(0.25, 40.0);
                          final minVisible = _minVisibleDays.clamp(0.0, maxX);
                          final nextVisible = (_gestureStartVisibleDays / scale)
                              .clamp(minVisible, maxX);
                          final focalRatio =
                              (details.localFocalPoint.dx / _plotWidth).clamp(
                                0.0,
                                1.0,
                              );
                          final focalX =
                              _gestureStartStartX +
                              (_gestureStartVisibleDays * focalRatio);
                          final nextStart = focalX - (nextVisible * focalRatio);
                          final maxStart = max(0.0, maxX - nextVisible);
                          setState(() {
                            _visibleDays = nextVisible;
                            _startX = nextStart.clamp(0.0, maxStart);
                          });
                          return;
                        }

                        final daysPerPixel = _visibleDays / _plotWidth;
                        final nextStart =
                            _startX -
                            (details.focalPointDelta.dx * daysPerPixel);
                        final maxStart = max(0.0, maxX - _visibleDays);
                        setState(() {
                          _startX = nextStart.clamp(0.0, maxStart);
                        });
                      },
                      onScaleEnd: (_) => setState(() {}),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const SizedBox.expand(),
                          _buildChart(
                            fullLayout,
                            lang: lang,
                            lineColor: lineColor,
                            japaneseLineColor: japaneseLineColor,
                            mutedText: mutedText,
                            minX: viewport.start,
                            maxX: viewport.end,
                            visibleSpan: viewport.span,
                            labelInterval: labelInterval,
                            plotWidth: _plotWidth,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 表示中の横軸幅と描画幅から、ラベルが重ならない目盛り間隔（日単位）を決める。
  static double _chartLabelInterval({
    required double visibleSpan,
    required double plotWidth,
  }) {
    if (visibleSpan <= 0 || plotWidth <= 0) return 1;

    final minIntervalFromPixels = visibleSpan * _minLabelSpacingPx / plotWidth;

    double targetTickCount;
    if (visibleSpan < 1 / 24) {
      targetTickCount = 3;
    } else if (visibleSpan < 1) {
      targetTickCount = 4;
    } else if (visibleSpan < 7) {
      targetTickCount = 5;
    } else {
      targetTickCount = 6;
    }

    var interval = visibleSpan / targetTickCount;
    if (visibleSpan >= 1) {
      interval = _niceDayInterval(interval);
    } else {
      interval = _niceSubDayInterval(interval);
    }

    return interval
        .clamp(minIntervalFromPixels, visibleSpan)
        .clamp(_minVisibleDays, visibleSpan);
  }

  /// 1日以上の表示向けに、見やすい日数ステップへ丸める。
  static double _niceDayInterval(double rawDays) {
    const steps = [1.0, 2.0, 3.0, 5.0, 7.0, 14.0, 30.0, 60.0, 90.0];
    for (final step in steps) {
      if (rawDays <= step) return step;
    }
    return (rawDays / 30).ceil() * 30.0;
  }

  /// 1日未満の表示向けに、見やすい時間ステップ（分）へ丸める。
  static double _niceSubDayInterval(double rawDays) {
    const minuteSteps = [1, 2, 5, 10, 15, 30, 60, 120, 180, 360, 720, 1440];
    final rawMinutes = rawDays * 24 * 60;
    for (final minutes in minuteSteps) {
      if (rawMinutes <= minutes) return minutes / (24 * 60);
    }
    return 1;
  }

  static String _subDayAxisLabel(DateTime chartStart, double x) {
    final t = chartStart.add(
      Duration(milliseconds: (x * Duration.millisecondsPerDay).round()),
    );
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildChart(
    _GenkiChartLayout layout, {
    required String lang,
    required Color lineColor,
    required Color japaneseLineColor,
    required Color mutedText,
    required double minX,
    required double maxX,
    required double visibleSpan,
    required double plotWidth,
    double? labelInterval,
  }) {
    final genkiSpots = layout.genkiSpots;
    final japaneseSpots = layout.japaneseSpots;
    final axisAnchors = layout.axisAnchors;

    if (genkiSpots.isEmpty) {
      return Center(
        child: Text(
          'まだデータがないよ。\n話すとここに元気度が記録されるよ。'.tr(lang),
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedText),
        ),
      );
    }

    final safeSpan = visibleSpan.clamp(_minVisibleDays, layout.maxX);
    final safeMaxX = maxX > minX ? maxX : minX + _minVisibleDays;
    final displayLabelInterval =
        labelInterval ??
        _chartLabelInterval(visibleSpan: safeSpan, plotWidth: plotWidth);
    final showJapaneseLine = japaneseSpots.isNotEmpty;
    final useSubDayAxis = safeSpan < 1;
    final chartStart = axisAnchors.isEmpty ? DateTime.now() : axisAnchors.first;
    // fl_chart は 0 起点の等間隔 tick しか出せないため、細かい間隔で tick を
    // 生成し getTitlesWidget 側で minX 基準に間引く（日付・時刻とも）。
    final bottomTickInterval = useSubDayAxis ? _minVisibleDays : 1.0;

    return IgnorePointer(
      child: LineChart(
        key: ValueKey(
          '${minX.toStringAsFixed(4)}'
          '-${safeMaxX.toStringAsFixed(4)}'
          '-$displayLabelInterval'
          '-$plotWidth',
        ),
        LineChartData(
          minX: minX,
          maxX: safeMaxX,
          // 元気度が 0 or 10 ちょうどのとき、ドット（半径3px）が上下端で
          // 半分だけ描画されてしまう（clip 境界＝軸の 0/10 ラインと重なるため）。
          // 上下にわずかな余白を持たせて、境界からドットを離す。
          minY: -0.5,
          maxY: 10.5,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: mutedText.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                // minY/maxY に足した余白(-0.5/10.5)ぶんの目盛りを増やさない。
                minIncluded: false,
                maxIncluded: false,
                reservedSize: _GenkiLineChart._leftAxisWidth,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: mutedText, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: bottomTickInterval,
                reservedSize: _GenkiLineChart._bottomAxisHeight - 8,
                getTitlesWidget: (value, meta) {
                  if (value < minX - bottomTickInterval * 0.5 ||
                      value > safeMaxX + bottomTickInterval * 0.5) {
                    return const SizedBox.shrink();
                  }

                  late final String label;
                  if (useSubDayAxis) {
                    final rel = value - minX;
                    if (rel < -0.0001) return const SizedBox.shrink();
                    final slotIndex = (rel / displayLabelInterval).round();
                    final snapped = minX + slotIndex * displayLabelInterval;
                    if ((value - snapped).abs() > bottomTickInterval * 0.55) {
                      return const SizedBox.shrink();
                    }
                    if (snapped > safeMaxX + 0.0001) {
                      return const SizedBox.shrink();
                    }
                    label = _subDayAxisLabel(chartStart, snapped);
                  } else {
                    final rel = value - minX;
                    if (rel < -0.01) return const SizedBox.shrink();
                    final slotIndex = (rel / displayLabelInterval).round();
                    final snapped = minX + slotIndex * displayLabelInterval;
                    if ((value - snapped).abs() > 0.45) {
                      return const SizedBox.shrink();
                    }
                    if (snapped > safeMaxX + 0.01) {
                      return const SizedBox.shrink();
                    }
                    final index = snapped.round();
                    if (index < 0 || index >= axisAnchors.length) {
                      return const SizedBox.shrink();
                    }
                    label = AppStrings.chartAxisLabel(
                      axisAnchors[index],
                      lang,
                      showYear: layout.showYearOnAxis,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(color: mutedText, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: false,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  AppColors.current.textOnCardPrimary.withValues(alpha: 0.87),
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final isJapanese = s.barIndex == 1;
                final label = isJapanese
                    ? '${'日本語評点'.tr(lang)}: '
                          '${s.y.round()}'
                    : '${'元気度'.tr(lang)}: ${s.y.toInt()}';
                return LineTooltipItem(
                  label,
                  TextStyle(
                    color: AppColors.current.onAccent.withValues(
                      alpha: isJapanese ? 0.7 : 1,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: genkiSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              preventCurveOvershootingThreshold: 4,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: lineColor,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            if (showJapaneseLine)
              LineChartBarData(
                spots: japaneseSpots,
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                preventCurveOvershootingThreshold: 4,
                color: japaneseLineColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dashArray: const [6, 4],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 2.5,
                        color: japaneseLineColor,
                        strokeWidth: 0,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// グラフ上部に表示する、2本の折れ線の凡例（色ドット＋ラベル）。
class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.genkiColor,
    required this.japaneseColor,
    required this.showJapanese,
    required this.mutedText,
    required this.lang,
  });

  final Color genkiColor;
  final Color japaneseColor;
  final bool showJapanese;
  final Color mutedText;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(color: genkiColor, label: '元気度'.tr(lang), muted: mutedText),
        if (showJapanese)
          _LegendItem(
            color: japaneseColor,
            label: '日本語評点'.tr(lang),
            muted: mutedText,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.muted,
  });

  final Color color;
  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: muted, fontSize: 11)),
      ],
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({
    required this.focusedMonth,
    required this.byDay,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.frameStyle,
  });

  final DateTime focusedMonth;
  final Map<String, _DailyGenki> byDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final FrameResolvedStyle frameStyle;

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final startMonday = appSettings.weekStartsMonday;
    final weekdayLabels = AppStrings.weekdayLabels(
      lang,
      startMonday: startMonday,
    );
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // DateTime.weekday: 月=1 ... 日=7。グリッドの先頭曜日（日曜または月曜）に合わせて0〜6に変換。
    final leadingEmptyCells = startMonday
        ? (firstDayOfMonth.weekday - 1) % 7
        : firstDayOfMonth.weekday % 7;
    final today = DateTime.now();

    final primaryText = frameStyle.readablePrimaryText;
    final mutedText = frameStyle.readableSecondaryText;
    // 日付数字＋ドットが文字サイズ設定でも収まるようセル高さを追従させる。
    final textScaler = MediaQuery.textScalerOf(context);
    final cellExtent = max(40.0, textScaler.scale(13) * 1.2 + 2 + 6 + 8);

    return GenkiFrameCard(
      style: frameStyle,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: primaryText),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month - 1),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.monthYearLabel(focusedMonth, lang),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: primaryText),
                onPressed: () => onMonthChanged(
                  DateTime(focusedMonth.year, focusedMonth.month + 1),
                ),
              ),
            ],
          ),
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(color: mutedText, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: cellExtent,
            ),
            itemCount: leadingEmptyCells + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) return const SizedBox.shrink();

              final day = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                index - leadingEmptyCells + 1,
              );
              final daily = byDay[DiaryStorage.dateKeyFor(day)];
              final isToday = _isSameDay(day, today);
              final isSelected =
                  selectedDay != null && _isSameDay(day, selectedDay!);

              return GestureDetector(
                onTap: daily == null ? null : () => onDaySelected(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: mutedText.withValues(alpha: 0.6))
                        : null,
                    color: isSelected
                        ? frameStyle.accentStrip.withValues(alpha: 0.16)
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: primaryText.withValues(
                              alpha: daily == null ? 0.35 : 1,
                            ),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: daily == null
                                ? Colors.transparent
                                : _colorForScore(daily.averageScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 元気度が高いほどアクセントストライプ色に、低いほど落ち着いたグレーになるよう補間する。
  Color _colorForScore(int score) {
    final t = (score / 10).clamp(0.0, 1.0);
    return Color.lerp(
      frameStyle.readableSecondaryText,
      frameStyle.accentStrip,
      t,
    )!;
  }
}
