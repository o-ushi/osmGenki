/// アプリ全体で共有するマジックナンバー。
abstract final class AppConstants {
  /// Chrome AIモードへ渡すURLの文字数上限（超過時はクエリなしURLへフォールバック）。
  static const chromeUrlMaxLength = 7500;

  /// 日記レビュー用プロンプトに載せる記録行の文字数バジェット。
  static const diaryReviewLineBudget = 550;

  /// Chrome往復から復帰した直後、キープアライブ復旧を待つ遅延。
  static const chromeKeepAliveRecoverDelay = Duration(milliseconds: 400);

  /// [SwipeToCloseWrapper] の閉じ判定速度閾値（論理ピクセル/秒）。
  static const swipeCloseVelocityThreshold = 250.0;
}
