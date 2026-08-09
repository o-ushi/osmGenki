import 'package:url_launcher/url_launcher.dart';

import '../app_constants.dart';

/// iOS `GoogleAIModeLink` / osmWashabe [GoogleAiLink] に対応。
abstract final class GoogleAiLink {
  static Uri webSearchUrl({required String prompt, required String lang}) {
    final query = _searchQuery(prompt, lang);
    final hl = _hl(lang);
    final uri = Uri.https('www.google.co.jp', '/search', {
      'q': query,
      'udm': '50',
      'hl': hl,
      'gl': 'jp',
      'ie': 'UTF-8',
    });
    if (uri.toString().length <= AppConstants.chromeUrlMaxLength) return uri;
    return Uri.https('www.google.co.jp', '/search', {
      'udm': '50',
      'hl': hl,
      'gl': 'jp',
    });
  }

  static Future<bool> openWithPrompt(
    String prompt, {
    required String lang,
  }) async {
    final web = webSearchUrl(prompt: prompt, lang: lang);
    final chrome = web.replace(scheme: 'googlechromes');
    if (await canLaunchUrl(chrome)) {
      return launchUrl(chrome, mode: LaunchMode.externalApplication);
    }
    return launchUrl(web, mode: LaunchMode.externalApplication);
  }

  static String _hl(String lang) => switch (lang) {
    'en' => 'en',
    'vi' => 'vi',
    _ => 'ja',
  };

  /// 回答言語を指示する接頭辞。プロンプト本文が末尾で指示する言語と矛盾すると
  /// AIの回答言語がぶれるため、ここでも[lang]に合わせて出し分ける。
  static String _searchQuery(String prompt, String lang) {
    final trimmed = prompt.trim();
    final prefix = switch (lang) {
      'en' => 'In English, ',
      'vi' => 'Bằng tiếng Việt, ',
      _ => '日本語で ',
    };
    if (trimmed.isEmpty) return prefix;
    if (trimmed.startsWith(prefix)) return trimmed;
    return '$prefix$trimmed';
  }
}
