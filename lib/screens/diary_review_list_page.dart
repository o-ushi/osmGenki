import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/diary_review_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/delete_swipe_background.dart';
import '../widgets/diary_review_dialog.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/swipe_down_to_dismiss.dart';

/// 「診断」（日記を見てもらう）で過去に貼り付けたアドバイスの一覧。「閲覧」ボタンから開く。
class DiaryReviewListPage extends StatefulWidget {
  const DiaryReviewListPage({super.key});

  @override
  State<DiaryReviewListPage> createState() => _DiaryReviewListPageState();
}

class _DiaryReviewListPageState extends State<DiaryReviewListPage> {
  late Future<List<DiaryReview>> _reviewsFuture;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _reviewsFuture = DiaryReviewStorage.loadAll();
    DiaryReviewStorage.changes.addListener(_onChanged);
  }

  @override
  void dispose() {
    DiaryReviewStorage.changes.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _reviewsFuture = DiaryReviewStorage.loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return SwipeDownToDismiss(
      scrollController: _scrollController,
      child: GenkiSubpageScaffold(
        title: '診断結果'.tr(lang),
        body: FutureBuilder<List<DiaryReview>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data ?? const [];
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'まだ診断結果がないよ。\n「診断」から日記を見てもらってね。'.tr(lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.current.textOnSubpageSecondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Dismissible(
                  key: ValueKey(review.date.toIso8601String()),
                  direction: DismissDirection.endToStart,
                  background: const DeleteSwipeBackground(),
                  confirmDismiss: (_) => confirmDelete(
                    context,
                    lang: lang,
                    bodyKey: '診断結果削除_確認',
                  ),
                  onDismissed: (_) => DiaryReviewStorage.remove(review),
                  child: _DiaryReviewCard(
                    review: review,
                    lang: lang,
                    onTap: () => showDiaryReviewDialog(
                      context: context,
                      lang: lang,
                      text: review.text,
                      date: review.date,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DiaryReviewCard extends StatelessWidget {
  const _DiaryReviewCard({
    required this.review,
    required this.lang,
    required this.onTap,
  });

  final DiaryReview review;
  final String lang;
  final VoidCallback onTap;

  /// カードに表示する本文の抜粋（1行目のみ、長ければ省略）。
  String get _preview {
    final firstLine = review.text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return firstLine;
  }

  @override
  Widget build(BuildContext context) {
    final time =
        '${review.date.hour.toString().padLeft(2, '0')}:'
        '${review.date.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.current.cardFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.dateLabel(review.date, lang)} $time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.current.textOnCardPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.current.textOnCardSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
