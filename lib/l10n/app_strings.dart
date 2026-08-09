import 'dart:math';

/// osmWashabeのローカライズ方式（キー=日本語文字列のフラットなMap）を踏襲。
abstract final class AppStrings {
  static String text(String key, String languageCode) {
    final lang = switch (languageCode) {
      'en' => 'en',
      'ja' => 'ja',
      _ => 'vi',
    };
    return _data[lang]?[key] ?? _data['ja']?[key] ?? key;
  }

  static const _data = <String, Map<String, String>>{
    'ja': _ja,
    'en': _en,
    'vi': _vi,
  };

  static const _ja = <String, String>{
    '設定': '設定',
    'その他': 'その他',
    'リセット': 'リセット',
    '会話をリセットしますか？': '会話をリセットしますか？',
    '会話リセット_確認': '録音した音声と文字起こし結果を削除し、最初の状態に戻します。この操作は取り消せません。',
    '言語': '言語',
    'アプリの表示言語を変更できます。': 'アプリの表示言語を変更できます。',
    'スタートアップ_説明': 'いま感じていること\n思っていることを\n言葉にしてみよう',
    '起動_操作ヒント_前': '各画面の',
    '起動_操作ヒント_後': 'ボタン長押しで\n操作方法を確認できます',
    'ヘルプ_録音_手順1': '1️⃣ 録音時間を選ぶ',
    'ヘルプ_録音_手順2': '2️⃣ {{icon}}ボタンをタップして録音開始',
    'ヘルプ_録音_手順3': '3️⃣ 録音終了',
    'ヘルプ_録音_手順3a': '♾️ もう一度{{icon}}ボタンをタップ',
    'ヘルプ_録音_手順3b': '30/45/60 タイマーゼロで自動停止',
    'ヘルプ_録音_手順4': '4️⃣ {{icon}}ボタンでAI診断',
    'ヘルプ_録音_手順5': '5️⃣ 診断結果をコピペして日記に記録',
    'ヘルプ_ダッシュボード_見出しグラフ': '<グラフ>',
    'ヘルプ_ダッシュボード_グラフ1': '会話力と元気度の時系列変化',
    'ヘルプ_ダッシュボード_グラフ2': 'スワイプで移動',
    'ヘルプ_ダッシュボード_グラフ3': 'ピンチで拡大/縮小',
    'ヘルプ_ダッシュボード_見出しカレンダー': '<カレンダー>',
    'ヘルプ_ダッシュボード_カレンダー1': '日付をタップ→その日の記録を表示',
    'ヘルプ_日記_手順1': '元気度/会話力長押しで詳細結果表示',
    'ヘルプ_日記_手順2': '{{icon}}ボタンでこれまでの日記をAI診断',
    'ヘルプ_日記_手順3': '診断結果をコピペして日記診断に記録',
    '次回から表示しない': '次回から表示しない',
    'はじめる': 'はじめる',
    'スタートアップ画面': 'スタートアップ画面',
    'スタートアップ画面_説明': 'アプリ起動時に案内画面を表示します',
    '操作': '操作',
    'シェイクで話す': 'シェイクで話す',
    'シェイクで話す_説明': '端末を振ると「話す」タブに切り替えます',
    '気分_最悪': 'とても元気じゃない',
    '気分_いまいち': 'いまいち',
    '気分_まあまあ': 'まあまあ',
    '気分_良い': '良い',
    '気分_最高': '最高',
    '週の開始': '週の開始',
    'カレンダーの週の始まりを選べます。': 'カレンダーの週の始まりを選べます。',
    '日曜始まり': '日曜始まり',
    '月曜始まり': '月曜始まり',
    'タイマー設定': 'タイマー設定',
    'タイマー音': 'タイマー音',
    '利用できる音がありません': '利用できる音がありません',
    '通知音_なし': 'なし',
    '通知音_不明': '不明',
    '通知音_三連音': '三連音',
    '通知音_アンティシペート': 'アンティシペート',
    '通知音_ブルーム': 'ブルーム',
    '通知音_カリプソ': 'カリプソ',
    '通知音_チューチュー': 'チューチュー',
    '通知音_ディセント': 'ディセント',
    '通知音_ファンファーレ': 'ファンファーレ',
    '通知音_ラダー': 'ラダー',
    '通知音_メヌエット': 'メヌエット',
    '通知音_ニュース': 'ニュース',
    '通知音_ノワール': 'ノワール',
    '通知音_シャーウッド': 'シャーウッド',
    '通知音_スペル': 'スペル',
    '通知音_サスペンス': 'サスペンス',
    '通知音_テレグラフ': 'テレグラフ',
    '通知音_ティプトゥ': 'ティプトゥ',
    '通知音_タイプライター': 'タイプライター',
    '通知音_アップデート': 'アップデート',
    '標準': '標準',
    '録音中...': '録音中...',
    '考え中...': '考え中...',
    '文字起こし準備中...': '文字起こし準備中...',
    '声が届かなかったみたい…もう一度試してね': '声が届かなかったみたい…もう一度試してね',
    'もう少し長く話してから離してね': 'もう少し長く話してから離してね',
    'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね': 'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね',
    '音声認識が使えないみたい。ネットワークを確認してね': '音声認識が使えないみたい。ネットワークを確認してね',
    '録音がうまくいかなかったみたい…もう一度試してね': '録音がうまくいかなかったみたい…もう一度試してね',
    'フリー': 'フリー',
    '30秒': '30秒',
    '45秒': '45秒',
    '60秒': '60秒',
    'どんな気分？\n教えてよ': 'どんな気分？\n教えてよ',
    'へぇ、そうなんだ\nもう少し聞かせて': 'へぇ、そうなんだ\nもう少し聞かせて',
    'なるほど\nどんなことを考えているの？': 'なるほど\nどんなことを考えているの？',
    'そう感じたんだね\n詳しくおしえて': 'そう感じたんだね\n詳しくおしえて',
    'その気持ちについて\n話してみて': 'その気持ちについて\n話してみて',
    '何がそう\n思わせたのかな？': '何がそう\n思わせたのかな？',
    '最近の様子を\n聞かせて': '最近の様子を\n聞かせて',
    '今の気持ちを\n言葉にしてみよう': '今の気持ちを\n言葉にしてみよう',
    '思いつくままに\n話してみて': '思いつくままに\n話してみて',
    '振り返りダッシュボード': '振り返りダッシュボード',
    'ボイス日記一覧': 'ボイス日記一覧',
    'まだ日記がないよ。\n話してみてね。': 'まだ日記がないよ。\n話してみてね。',
    'スコアの推移': 'スコアの推移',
    'まだデータがないよ。\n話すとここに元気度が記録されるよ。': 'まだデータがないよ。\n話すとここに元気度が記録されるよ。',
    '話す': '話す',
    '元気度': '元気度',
    '元気度の起点': '元気度の起点',
    'ポジティブ度': 'ポジティブ度',
    'ストレス度': 'ストレス度',
    '疲労感': '疲労感',
    '意欲': '意欲',
    '加減点': '加減点',
    '最終元気度': '最終元気度',
    '理由': '理由',
    '日本語評点': '日本語評点',
    '会話力': '会話力',
    'スコアの内訳': 'スコアの内訳',
    'スコア内訳_説明': 'osmWashabeと同じJSST採点手法で、発話のタイミングと文字数から推定した指標です。',
    'スコア内訳_データなし': 'この記録には詳細データがありません（新しい記録から表示されます）。',
    'スコア内訳_時間の利用率_定義': '推定発話時間を発話枠で割った割合です。認識した文字数から、どれくらい話していたと推定できるかを示します。',
    'スコア内訳_推定沈黙の割合_定義':
        '推定沈黙時間を発話枠で割った割合です。話し始めるまでの間や、発話と発話のあいだなど、黙っていたと推定される時間の割合です。',
    '時間の使い方': '時間の使い方',
    '発話枠': '発話枠',
    '秒': '秒',
    '発話文字数': '発話文字数',
    '枠あたりの発話量': '枠あたりの発話量',
    '字/分': '字/分',
    '推定発話時間': '推定発話時間',
    '時間の利用率': '時間の利用率',
    '推定沈黙の割合': '推定沈黙の割合',
    '長い沈黙（4秒以上）': '長い沈黙（4秒以上）',
    '回': '回',
    'JSST 1〜2': 'JSST 1〜2',
    'JSST 3〜4': 'JSST 3〜4',
    'JSST 5〜6': 'JSST 5〜6',
    'JSST 7〜': 'JSST 7〜',
    'キャリブレーション（開発者）': 'キャリブレーション（開発者）',
    '参考レベルが算出できませんでした。キャリブレーションは利用できません。':
        '参考レベルが算出できませんでした。キャリブレーションは利用できません。',
    '補正係数': '補正係数',
    '評価傾向': '評価傾向',
    '学習回数': '学習回数',
    '補正後レベル': '補正後レベル',
    '自己評価を入力 (JSST 1–10)': '自己評価を入力 (JSST 1–10)',
    '適用': '適用',
    '甘め': '甘め',
    '辛め': '辛め',
    'ヘルプ': 'ヘルプ',
    'バージョン %@ (%@)': 'バージョン %@ (%@)',
    'ヘルプ紹介文':
        '日本語の会話力（流暢さなど）を伸ばすアプリです。姉妹アプリosmWashabeが正解を求めずに'
        '45〜60秒話し切ることに重きを置いているのに対して、osmGenki？は'
        '答えを探しながら話すことに重きを置いています。'
        '画面に出すのは元気度と会話力の目安で、Washabeのような多軸の詳細採点UIではありません。'
        'アプリからの「元気してる？」の問い掛けに色々と思いを巡らしながら話してみてください。',
    '基本操作': '基本操作',
    'help.talk.title': 'タップで話す',
    'help.talk.body':
        '画面中央のマイクボタンをタップして話してください。'
        'ツールバー下の「フリー」「30秒」「45秒」「60秒」から録音のしかたを選べます。\n'
        '「フリー」はタップすると録音が始まり、もう一度タップすると録音が止まります。'
        '秒数を選んだ場合はタップ1回で録音とカウントダウンが始まり、'
        '0になるとチャイムが鳴って自動で止まります。'
        'カウントダウン中にもう一度タップすると、一時停止・再開ができます。',
    'help.rally.title': '続けて話せる',
    'help.rally.body':
        'マイクボタンで話した内容は、送信するまでどんどん追記されていきます。'
        '一息で言い切れなくても、何度かに分けて話しかけても大丈夫です。'
        'やり直したいときは、リセットボタンでいつでも最初から話せます。',
    'help.time.title': '声かけはランダム',
    'help.time.body':
        'マイク画面でまだ何も話していないときに出る声かけ文は、'
        '何パターンかの中からランダムに選ばれます。'
        '毎回同じ言葉とは限らないので、気軽に話しかけてください。',
    'help.shake.title': 'シェイクで話す',
    'help.shake.body':
        '端末を振ると「話す」タブに切り替わります。'
        '設定の「操作」からオフにもできます。',
    'Chromeとのやりとり': 'Chromeとのやりとり',
    'help.chrome.step1.title': '① まずは話しかけましょう',
    'help.chrome.step1.body':
        'マイクのボタンをタップして、今日あったことを話してください。'
        '話し終わったら、もう一度タップすれば録音が止まります。',
    'help.chrome.step2.title': '② 飛行機ボタンを押すとChromeが開きます',
    'help.chrome.step2.body':
        '話した内容がまとまったら、下にある飛行機ボタンを押してください。'
        '文章が自動でコピーされて、Chromeというアプリが開きます。'
        'そこでAI（人工知能）が、元気度と会話力（流暢さなどの目安）を考えてくれます。',
    'help.chrome.step3.title': '③ 答えが出たらコピーしましょう',
    'help.chrome.step3.body':
        'Chromeの画面に答えが出てきたら、回答の下にあるコピーボタン（%ICON%）をタップしてコピーしてください。\n'
        'ボタンが見つからない・反応しない場合は、回答を長押し→「すべて選択」→「コピー」でも大丈夫です。\n'
        'コピーできたら、このアプリに戻ってきてください。',
    'help.chrome.step4.title': '④ ペーストボタンで保存しましょう',
    'help.chrome.step4.body':
        'アプリに戻ったら、下にあるペーストボタンを押してください。'
        'コピーした答えを読み取って、すぐに日記に記録されます。',
    '振り返り': '振り返り',
    '日記をエクスポート': '日記をエクスポート',
    'エクスポートに失敗しました': 'エクスポートに失敗しました',
    'エクスポートする日記がありません': 'エクスポートする日記がありません',
    '日記をエクスポートしました_件数': '%@件の日記をエクスポートしました。',
    '日記をエクスポートしました_件数_診断結果あり': '%@件の日記と%@件の診断結果をエクスポートしました。',
    '日記をインポート': '日記をインポート',
    'インポート完了': 'インポート完了',
    '日記をインポートしました': '%@件の日記をインポートしました。',
    '日記をインポートしました_スキップあり': '%@件の日記をインポートしました。\n（%@件は既に存在するためスキップしました）',
    '日記をインポートしました_すべてスキップ': 'ファイル内の%@件は、すべて端末内に既にあるため追加されませんでした。',
    '診断結果をインポートしました': '%@件の診断結果をインポートしました。',
    '診断結果をインポートしました_スキップあり': '%@件の診断結果をインポートしました。\n（%@件は既に存在するためスキップしました）',
    '診断結果をインポートしました_すべてスキップ': 'ファイル内の診断結果%@件は、すべて端末内に既にあるため追加されませんでした。',
    'インポートエラー': 'インポートエラー',
    'インポート失敗_メッセージ': 'ファイルの読み込みに失敗しました: %@',
    'OK': 'OK',
    '初期化_説明': '端末内のすべてのデータ（日記・診断結果・録音・設定など）を削除し、初めてインストールした状態に戻します。',
    '初期化_確認': '端末内のすべてのデータ（日記・診断結果・録音・設定など）を削除し、初めてインストールした状態に戻します。この操作は取り消せません。',
    '初期化しますか？': 'すべてのデータを初期化しますか？',
    '初期化しました': 'すべてのデータを初期化しました',
    'キャンセル': 'キャンセル',
    '初期化': 'すべてのデータを初期化',
    'データ': 'データ',
    '削除しますか？': '削除しますか？',
    '日記削除_確認': 'この日記を削除します。この操作は取り消せません。',
    '削除': '削除',
    'help.dashboard.title': 'ダッシュボード',
    'help.dashboard.body':
        '右上のグラフアイコンから、元気度と会話力評点の推移をカレンダーと折れ線グラフで確認できます。'
        '記録が複数あるときは最初に全期間を表示します。'
        'グラフはピンチで拡大・縮小し、ドラッグで左右に動かせます。',
    'help.diary.title': 'ボイス日記',
    'help.diary.body':
        'Chromeとのやりとりが終わって貼り付けると、元気度・会話力評点つきの日記として'
        'この端末に保存されます。過去の記録は一覧からいつでも読み返せます。',
    'help.review.title': '日記を見てもらう',
    'help.review.body':
        'ボイス日記一覧の上部にある「診断」ボタンから、'
        'これまでの記録をもとに、Chromeでアドバイスをもらえます。'
        'Chromeでアドバイスをコピーして貼り付けボタンを押すと保存され、その場で読めます。'
        '保存した結果は「閲覧」ボタンからいつでも見返せます。'
        'アプリの表示言語で答えてくれます。',
    '開発者モードを有効にしました': '開発者モードを有効にしました',
    '開発者モードを無効にしました': '開発者モードを無効にしました',
    '開発者向け': '開発者向け',
    '音声認識ログ': '音声認識ログ',
    '音声認識ログ_説明':
        '直近の音声認識の動きを端末に保存しています。フリーズした場合はアプリを再起動し、設定 → 音声認識ログ を開いてください。',
    '音声認識ログ_設定説明': 'フリーズ・クラッシュ後もここからログを確認できます。',
    '(ログなし)': '(ログなし)',
    '再読み込み': '再読み込み',
    'コピー': 'コピー',
    'コピーしました': 'コピーしました',
    'クリア': 'クリア',
    '元気してる？': '元気してる？',
    '送信': '送信',
    '聴き直す': '聴き直す',
    '停止': '停止',
    '貼り付け': '貼り付け',
    '解析結果を読み取れなかった': '元気度の加減点が読み取れなかったよ。「元気度の加減点: +2」のように書かれているか確認してね',
    'Chromeを開けなかった': 'Chromeを開けなかったよ。端末にブラウザが入っているか確認してね',
    'Chrome AI解析結果_元気度のみ': 'Chrome AIの解析結果（元気度: %@）',
    'Chrome AI解析結果': 'Chrome AIの解析結果（元気度: %@ / 日本語レベル: %@）',
    '結果を保存しました': '結果を保存しました',
    'ヒント_送信待ち': '話し終わったら飛行機ボタンを押して、Chromeに診断してもらおう。',
    'ヒント_貼り付け待ち': 'Chromeから戻ってきたらペーストボタンを押して、日記に記録しよう。',
    'アドバイス': 'アドバイス',
    'アドバイスを読み取れなかった': 'アドバイスが読み取れなかったよ。コピーできているか確認してね',
    'ヒント_日記レビュー貼り付け待ち': 'Chromeでアドバイスをコピーしたら、貼り付けボタンを押してね。',
    '診断': '診断',
    '閲覧': '閲覧',
    '診断結果': '診断結果',
    '診断結果削除_確認': 'この診断結果を削除します。この操作は取り消せません。',
    'まだ診断結果がないよ。\n「診断」から日記を見てもらってね。': 'まだ診断結果がないよ。\n「診断」から日記を見てもらってね。',
    'プライバシー': 'プライバシー',
    'OS音声認識': 'OS音声認識',
    'Google AI': 'Google AI',
    '保存・削除・バックアップ': '保存・削除・バックアップ',
    'Appleプライバシーポリシー': 'Appleプライバシーポリシー',
    'Googleプライバシーポリシー': 'Googleプライバシーポリシー',
    '本アプリのプライバシーポリシー': '本アプリのプライバシーポリシー',
    '音声認識同意_タイトル': '録音音声の外部処理について',
    '音声認識同意_本文':
        '文字起こしのため、録音した音声データが、iOSではApple、Androidでは端末設定の音声認識事業者（Googleまたは端末メーカー等）へ渡り、クラウドで処理される場合があります。事業者は音声データを文字起こしの目的で処理します。オフライン認識へ切り替わる場合もあります。同意は設定 → プライバシーからいつでも撤回でき、未同意または撤回後は録音・音声認識を開始しません。',
    '音声認識同意_本文_iOS':
        '文字起こしのため、録音した音声データをOSに搭載された音声認識サービス（Apple Inc.のSpeech Recognition）へ渡します。Appleのサーバーで処理される場合があります。同意は設定 → プライバシーからいつでも撤回でき、未同意または撤回後は録音・音声認識を開始しません。Appleの規約・プライバシーポリシーが適用されます。',
    '音声認識同意_本文_Android':
        '文字起こしのため、録音した音声データを端末のOS音声認識サービスへ渡します。認識に失敗した場合のみ、端末内のVoskモデル（オフライン）で処理し、外部へは送信しません。同意は設定 → プライバシーからいつでも撤回でき、未同意または撤回後は録音・音声認識を開始しません。',
    '同意しない': '同意しない',
    '同意する': '同意する',
    '同意を撤回': '同意を撤回',
    '撤回する': '撤回する',
    '未同意': '未同意',
    '同意中': '同意中',
    '音声認識同意_撤回確認タイトル': '音声認識への同意を撤回しますか？',
    '音声認識同意_撤回確認本文': '撤回後は、再度同意するまで録音と音声認識を開始できません。',
    'Privacy_音声認識説明_iOS':
        '録音した音声を、OSに搭載された音声認識サービスへ送信します。目的は発話の文字起こしです。初めて利用する前に同意を確認し、同意しない場合も音声認識を使わない機能は利用できます。Appleの規約・プライバシーポリシーが適用されます。',
    'Privacy_音声認識説明_Android':
        '録音した音声を、OSに搭載された音声認識サービス、もしくはVosk（端末内のオフラインモデル）へ送信します。目的は、発話の文字起こしです。初めて利用する前に同意を確認し、同意しない場合も音声認識を使わない機能は利用できます。',
    'Privacy_設定への案内':
        '表示言語やシェイクで話すなどの操作設定は、設定画面から変更できます。',
    'Privacy_Google説明':
        '発話解析または日記傾向の診断を実行するたびに、Google LLCへの送信内容と目的を表示して同意を確認します。拒否した場合はクリップボードへのコピーもブラウザ起動も行いません。',
    'Privacy_保存削除説明':
        '日記、診断結果、設定、直近の録音は端末内に保存されます。個別削除または「初期化」で削除できます。初期化は録音、破損データの退避、一時エクスポートも削除します。バックアップは操作時にJSONとして一時作成され、共有先に保存したコピーは本アプリから削除できません。',
    'Google送信確認_タイトル_発言': '発言の内容をGoogleに送信しますか？',
    'Google送信確認_本文_発言':
        'Google LLCが提供するGoogle検索（AIモード）へ、発話の文字起こし全文と解析指示（要約、元気度、日本語会話力の評価および出力形式）を送信します。目的は元気度と会話力の解析です。発話には氏名、健康状態、生活上の出来事などの個人情報が含まれる可能性があります。Googleへの送信は検索履歴や、ログイン中のGoogleアカウント履歴に記録・関連付けられる可能性があります。',
    'Google送信確認_タイトル_日記': '日記の記録をGoogleに送信しますか？',
    'Google送信確認_本文_日記':
        'Google LLCが提供するGoogle検索（AIモード）へ、保存済み日記の日付、元気度、会話力スコアと傾向解析の指示を送信します。目的は日記傾向に基づく助言の取得です。これらの記録には個人情報が含まれる可能性があります。Googleへの送信は検索履歴や、ログイン中のGoogleアカウント履歴に記録・関連付けられる可能性があります。',
  };

  static const _en = <String, String>{
    '設定': 'Settings',
    'その他': 'More',
    'リセット': 'Reset',
    '会話をリセットしますか？': 'Reset the conversation?',
    '会話リセット_確認':
        'This deletes the recorded audio and transcribed text, and returns '
        'to the start. This cannot be undone.',
    '言語': 'Language',
    'アプリの表示言語を変更できます。': 'You can change the app display language.',
    'スタートアップ_説明':
        'Put into words what you’re feeling\nand thinking right now.',
    '起動_操作ヒント_前': 'Long-press the ',
    '起動_操作ヒント_後': ' button on any screen\nto see how to use it',
    'ヘルプ_録音_手順1': '1️⃣ Choose a recording duration',
    'ヘルプ_録音_手順2': '2️⃣ Tap the {{icon}} button to start recording',
    'ヘルプ_録音_手順3': '3️⃣ End the recording',
    'ヘルプ_録音_手順3a': '♾️ Tap the {{icon}} button again',
    'ヘルプ_録音_手順3b':
        '30/45/60 Stops automatically when the timer hits zero',
    'ヘルプ_録音_手順4': '4️⃣ Tap the {{icon}} button for an AI check',
    'ヘルプ_録音_手順5':
        '5️⃣ Copy the result and paste it to save it in your diary',
    'ヘルプ_ダッシュボード_見出しグラフ': '<Graph>',
    'ヘルプ_ダッシュボード_グラフ1': 'Conversation skill and Genki score over time',
    'ヘルプ_ダッシュボード_グラフ2': 'Swipe to move',
    'ヘルプ_ダッシュボード_グラフ3': 'Pinch to zoom in/out',
    'ヘルプ_ダッシュボード_見出しカレンダー': '<Calendar>',
    'ヘルプ_ダッシュボード_カレンダー1': 'Tap a date to see that day’s record',
    'ヘルプ_日記_手順1':
        'Long-press the Genki score/conversation skill for details',
    'ヘルプ_日記_手順2':
        'Tap the {{icon}} button to have AI review your diary so far',
    'ヘルプ_日記_手順3':
        'Copy the result and paste it to save it as a diary review',
    '次回から表示しない': "Don't show again",
    'はじめる': 'Get started',
    'スタートアップ画面': 'Startup screen',
    'スタートアップ画面_説明': 'Show the welcome screen when the app launches',
    '操作': 'Controls',
    'シェイクで話す': 'Shake to talk',
    'シェイクで話す_説明': 'Shake the device to switch to the Talk tab',
    '気分_最悪': 'Not feeling well at all',
    '気分_いまいち': 'Not great',
    '気分_まあまあ': 'Okay',
    '気分_良い': 'Good',
    '気分_最高': 'Great',
    '週の開始': 'Week start',
    'カレンダーの週の始まりを選べます。': 'Choose which day the calendar week starts on.',
    '日曜始まり': 'Sunday',
    '月曜始まり': 'Monday',
    'タイマー設定': 'Timer settings',
    'タイマー音': 'Timer sound',
    '利用できる音がありません': 'No sounds available',
    '通知音_なし': 'None',
    '通知音_不明': 'Unknown',
    '通知音_三連音': 'Tri-tone',
    '通知音_アンティシペート': 'Anticipate',
    '通知音_ブルーム': 'Bloom',
    '通知音_カリプソ': 'Calypso',
    '通知音_チューチュー': 'Choo Choo',
    '通知音_ディセント': 'Descent',
    '通知音_ファンファーレ': 'Fanfare',
    '通知音_ラダー': 'Ladder',
    '通知音_メヌエット': 'Minuet',
    '通知音_ニュース': 'News Flash',
    '通知音_ノワール': 'Noir',
    '通知音_シャーウッド': 'Sherwood Forest',
    '通知音_スペル': 'Spell',
    '通知音_サスペンス': 'Suspense',
    '通知音_テレグラフ': 'Telegraph',
    '通知音_ティプトゥ': 'Tiptoes',
    '通知音_タイプライター': 'Typewriters',
    '通知音_アップデート': 'Update',
    '標準': 'Standard',
    '録音中...': 'Recording...',
    '考え中...': 'Thinking...',
    '文字起こし準備中...': 'Preparing transcription...',
    '声が届かなかったみたい…もう一度試してね': "Couldn't quite hear that... try again?",
    'もう少し長く話してから離してね': 'Hold a little longer, then release.',
    'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね':
        'Microphone and speech recognition access are needed. Turn them on in Settings.',
    '音声認識が使えないみたい。ネットワークを確認してね':
        "Speech recognition isn't available. Check your network connection.",
    '録音がうまくいかなかったみたい…もう一度試してね': "Recording didn't work... try again?",
    'フリー': 'Free',
    '30秒': '30 sec',
    '45秒': '45 sec',
    '60秒': '60 sec',
    'どんな気分？\n教えてよ': 'How are you feeling?\nTell me.',
    'へぇ、そうなんだ\nもう少し聞かせて': 'Oh, I see.\nTell me a bit more.',
    'なるほど\nどんなことを考えているの？': "I see.\nWhat's on your mind?",
    'そう感じたんだね\n詳しくおしえて': "So that's how you feel.\nTell me more.",
    'その気持ちについて\n話してみて': 'Talk about\nthat feeling.',
    '何がそう\n思わせたのかな？': 'What made you\nfeel that way?',
    '最近の様子を\n聞かせて': 'Tell me how things\nhave been lately.',
    '今の気持ちを\n言葉にしてみよう': 'Try putting your feelings\ninto words.',
    '思いつくままに\n話してみて': 'Just say whatever\ncomes to mind.',
    '振り返りダッシュボード': 'Reflection Dashboard',
    'ボイス日記一覧': 'Voice Diary List',
    'まだ日記がないよ。\n話してみてね。': 'No diary entries yet.\nTry talking.',
    'スコアの推移': 'Score Trend',
    'まだデータがないよ。\n話すとここに元気度が記録されるよ。':
        'No data yet.\nTalk and your energy will be recorded here.',
    '話す': 'Talk',
    '元気度': 'Energy',
    '元気度の起点': 'Energy baseline',
    'ポジティブ度': 'Positivity',
    'ストレス度': 'Stress level',
    '疲労感': 'Fatigue',
    '意欲': 'Motivation',
    '加減点': 'Adjustment',
    '最終元気度': 'Final energy',
    '理由': 'Reasons',
    '日本語評点': 'Japanese score',
    '会話力': 'Conversation skill',
    'スコアの内訳': 'Score breakdown',
    'スコア内訳_説明':
        'Estimated from speech timing and character count, using the same JSST scoring method as osmWashabe.',
    'スコア内訳_データなし':
        'No detailed data for this entry (available for new entries).',
    'スコア内訳_時間の利用率_定義':
        'Estimated speaking time divided by the speaking window. '
        'Shows how much of the window was likely spent speaking, based on recognized character count.',
    'スコア内訳_推定沈黙の割合_定義':
        'Estimated silence time divided by the speaking window. '
        'Includes time before the first utterance and gaps between utterances.',
    '時間の使い方': 'Time usage',
    '発話枠': 'Speaking window',
    '秒': 's',
    '発話文字数': 'Characters spoken',
    '枠あたりの発話量': 'Output per window',
    '字/分': ' chars/min',
    '推定発話時間': 'Est. speaking time',
    '時間の利用率': 'Time utilization',
    '推定沈黙の割合': 'Est. silence ratio',
    '長い沈黙（4秒以上）': 'Long pauses (≥4s)',
    '回': '',
    'JSST 1〜2': 'JSST 1–2',
    'JSST 3〜4': 'JSST 3–4',
    'JSST 5〜6': 'JSST 5–6',
    'JSST 7〜': 'JSST 7+',
    'キャリブレーション（開発者）': 'Calibration (Developer)',
    '参考レベルが算出できませんでした。キャリブレーションは利用できません。':
        'Reference level could not be calculated. Calibration is unavailable.',
    '補正係数': 'Correction factor',
    '評価傾向': 'Evaluation tendency',
    '学習回数': 'Learning count',
    '補正後レベル': 'Adjusted level',
    '自己評価を入力 (JSST 1–10)': 'Enter self-assessment (JSST 1–10)',
    '適用': 'Apply',
    '甘め': 'Lenient',
    '辛め': 'Strict',
    'ヘルプ': 'Help',
    'バージョン %@ (%@)': 'Version %@ (%@)',
    'ヘルプ紹介文':
        'An app to help you build Japanese conversation skill (such as fluency). '
        'While its sister app osmWashabe focuses on speaking for 45-60 '
        'seconds straight without worrying about a "correct" answer, '
        'osmGenki? focuses on speaking while you search for an answer. '
        'What you see here is an energy score and a conversation-skill guide — '
        'not Washabe\'s full multi-axis scoring UI. '
        'Try talking it through as different thoughts come to mind, '
        'in response to the app\'s question, "How are you feeling?"',
    '基本操作': 'Basics',
    'help.talk.title': 'Tap to talk',
    'help.talk.body':
        'Tap the mic button in the center to talk. '
        'Choose how recording works from "Free", "30 sec", "45 sec", or "60 sec" '
        'below the toolbar.\n'
        '"Free" starts recording when you tap it, and stops when you tap it '
        'again. '
        'Pick a duration instead and a single tap starts recording with a '
        'countdown; it chimes and stops automatically at zero. '
        'Tap again during the countdown to pause or resume.',
    'help.rally.title': 'Keep adding to what you say',
    'help.rally.body':
        'Whatever you say into the mic keeps getting appended until you send it. '
        "It's fine to speak in a few separate takes instead of all at once. "
        'Want to start over? The reset button clears everything at any time.',
    'help.time.title': 'Prompts are random',
    'help.time.body':
        "The prompt shown on the mic screen before you've said anything is "
        "picked randomly from several options each time, so it won't always "
        'be the same — just talk about whatever comes up.',
    'help.shake.title': 'Shake to talk',
    'help.shake.body':
        'Shake the device to switch to the Talk tab. '
        'You can turn this off under Controls in Settings.',
    'Chromeとのやりとり': 'Working with Chrome AI',
    'help.chrome.step1.title': '① Talk into the mic first',
    'help.chrome.step1.body':
        'Tap the mic button and talk about your day. '
        'Tap it again when you\'re done, and the recording stops.',
    'help.chrome.step2.title': '② Tap the airplane button to open Chrome',
    'help.chrome.step2.body':
        'Once your words are ready, tap the airplane button below. '
        'The text is copied automatically and Chrome opens for you. '
        'That\'s where the AI figures out your energy score and conversation '
        'skill (a fluency-oriented guide).',
    'help.chrome.step3.title': '③ Copy the answer when it appears',
    'help.chrome.step3.body':
        'When Chrome shows an answer, tap the copy button (%ICON%) below it to copy the text.\n'
        "If you can't find it or it doesn't respond, press and hold the answer → \"Select All\" → \"Copy\" instead.\n"
        'Once copied, come back to this app.',
    'help.chrome.step4.title': '④ Tap the paste button to save',
    'help.chrome.step4.body':
        'Back in the app, tap the paste button below. '
        'It reads the copied answer and saves it to your diary right away.',
    '振り返り': 'Reflection',
    '日記をエクスポート': 'Export diary',
    'エクスポートに失敗しました': 'Export failed',
    'エクスポートする日記がありません': 'No diary entries to export',
    '日記をエクスポートしました_件数': 'Exported %@ diary entries.',
    '日記をエクスポートしました_件数_診断結果あり':
        'Exported %@ diary entries and %@ diagnosis results.',
    '日記をインポート': 'Import diary',
    'インポート完了': 'Import Complete',
    '日記をインポートしました': 'Imported %@ diary entries.',
    '日記をインポートしました_スキップあり':
        'Imported %@ diary entries.\n(%@ skipped as they already exist)',
    '日記をインポートしました_すべてスキップ':
        'All %@ entries in the file already exist on this device, so nothing was added.',
    '診断結果をインポートしました': 'Imported %@ diagnosis results.',
    '診断結果をインポートしました_スキップあり':
        'Imported %@ diagnosis results.\n(%@ skipped as they already exist)',
    '診断結果をインポートしました_すべてスキップ':
        'All %@ diagnosis results in the file already exist on this device, '
        'so nothing was added.',
    'インポートエラー': 'Import Error',
    'インポート失敗_メッセージ': 'Failed to read file: %@',
    'OK': 'OK',
    '初期化_説明':
        'Deletes all data on this device (diary, diagnosis results, recordings, '
        'settings, and more) and restores the app to its just-installed state.',
    '初期化_確認':
        'All data on this device (diary, diagnosis results, recordings, settings, '
        'and more) will be deleted and the app restored to its just-installed '
        'state. This cannot be undone.',
    '初期化しますか？': 'Reset all data on this device?',
    '初期化しました': 'All data has been reset',
    'キャンセル': 'Cancel',
    '初期化': 'Reset all data',
    'データ': 'Data',
    '削除しますか？': 'Delete this entry?',
    '日記削除_確認': 'This diary entry will be deleted. This cannot be undone.',
    '削除': 'Delete',
    'help.dashboard.title': 'Dashboard',
    'help.dashboard.body':
        'Tap the chart icon to see your energy and conversation skill score '
        'trends on a calendar and line graph. With multiple entries, the graph '
        'starts by showing your full history. Pinch to zoom in or out, and '
        'drag to scroll left or right.',
    'help.diary.title': 'Voice diary',
    'help.diary.body':
        'Once you paste the result back from Chrome, it\'s saved on your '
        'device as a diary entry with your energy and conversation skill '
        'score. You can look back at past entries from the list anytime.',
    'help.review.title': 'Get advice on my diary',
    'help.review.body':
        'Tap "Diagnose" at the top of the voice diary list to get advice '
        'based on your record so far in Chrome. '
        'Copy the advice in Chrome and tap the paste button to save it and '
        'read it right away. You can revisit saved results anytime from '
        '"View". It answers in your app\'s display language.',
    '開発者モードを有効にしました': 'Developer mode enabled',
    '開発者モードを無効にしました': 'Developer mode disabled',
    '開発者向け': 'Developer',
    '音声認識ログ': 'Speech recognition log',
    '音声認識ログ_説明':
        'Recent speech recognition activity is saved on this device. '
        'If the app freezes, restart it and open Settings → Speech recognition log.',
    '音声認識ログ_設定説明': 'You can review logs here even after a freeze or crash.',
    '(ログなし)': '(No log)',
    '再読み込み': 'Reload',
    'コピー': 'Copy',
    'コピーしました': 'Copied',
    'クリア': 'Clear',
    '元気してる？': 'How are you feeling?',
    '送信': 'Send',
    '聴き直す': 'Play back',
    '停止': 'Stop',
    '貼り付け': 'Paste',
    '解析結果を読み取れなかった':
        'Couldn\'t find an energy adjustment. Make sure the text includes something like "Energy adjustment: +2".',
    'Chromeを開けなかった':
        'Couldn\'t open Chrome. Check that a browser is installed on this device.',
    'Chrome AI解析結果_元気度のみ': 'Chrome AI result (genki score: %@)',
    'Chrome AI解析結果': 'Chrome AI result (genki score: %@ / Japanese level: %@)',
    '結果を保存しました': 'Result saved',
    'ヒント_送信待ち':
        'When you\'re done talking, tap the airplane button and let Chrome analyze it.',
    'ヒント_貼り付け待ち':
        'When you\'re back from Chrome, tap the paste button to save it to your diary.',
    'アドバイス': 'Advice',
    'アドバイスを読み取れなかった': "Couldn't read the advice. Make sure you copied it.",
    'ヒント_日記レビュー貼り付け待ち':
        'Once you copy the advice in Chrome, tap the paste button.',
    '診断': 'Diagnose',
    '閲覧': 'View',
    '診断結果': 'Diagnosis results',
    '診断結果削除_確認':
        'This diagnosis result will be deleted. This cannot be undone.',
    'まだ診断結果がないよ。\n「診断」から日記を見てもらってね。':
        'No diagnosis results yet.\nTap "Diagnose" to get advice on your diary.',
    'プライバシー': 'Privacy',
    'OS音声認識': 'OS speech recognition',
    'Google AI': 'Google AI',
    '保存・削除・バックアップ': 'Storage, deletion & backup',
    'Appleプライバシーポリシー': 'Apple Privacy Policy',
    'Googleプライバシーポリシー': 'Google Privacy Policy',
    '本アプリのプライバシーポリシー': 'This App\'s Privacy Policy',
    '音声認識同意_タイトル': 'External processing of recorded audio',
    '音声認識同意_本文':
        'To create a transcript, recorded audio may be provided to Apple on iOS or to the speech-recognition provider configured on your Android device (such as Google or the device manufacturer), and may be processed in the cloud. The provider processes the audio to convert speech to text. Offline recognition may be used instead. You can withdraw consent anytime in Settings → Privacy. If you decline or withdraw, recording and speech recognition will not start.',
    '音声認識同意_本文_iOS':
        'To create a transcript, recorded audio is sent to the speech-recognition service built into the OS (Apple\'s Speech Recognition). It may be processed on Apple\'s servers. You can withdraw consent anytime in Settings → Privacy. If you decline or withdraw, recording and speech recognition will not start. Apple\'s terms and privacy policy apply.',
    '音声認識同意_本文_Android':
        'To create a transcript, recorded audio is sent to the speech-recognition service built into the OS. If recognition fails, it falls back to the on-device Vosk model (offline) and nothing is sent externally. You can withdraw consent anytime in Settings → Privacy. If you decline or withdraw, recording and speech recognition will not start.',
    '同意しない': 'Decline',
    '同意する': 'Agree',
    '同意を撤回': 'Withdraw consent',
    '撤回する': 'Withdraw',
    '未同意': 'Not agreed',
    '同意中': 'Agreed',
    '音声認識同意_撤回確認タイトル': 'Withdraw speech-recognition consent?',
    '音声認識同意_撤回確認本文':
        'Recording and speech recognition will remain disabled until you agree again.',
    'Privacy_音声認識説明_iOS':
        'Recorded audio is sent to the speech-recognition service built into the OS. The purpose is to create a transcript. Consent is requested before first use; features that do not use speech recognition remain available even if you decline. Apple’s terms and privacy policy apply.',
    'Privacy_音声認識説明_Android':
        'Recorded audio is sent to the speech-recognition service built into the OS, or to Vosk (an on-device offline model). The purpose is to create a transcript. Consent is requested before first use; features that do not use speech recognition remain available even if you decline.',
    'Privacy_設定への案内':
        'Display language and shake-to-talk controls are in Settings.',
    'Privacy_Google説明':
        'Before each speech analysis or diary-trend request, the app identifies what will be sent to Google LLC and why, and asks for consent. If you decline, it neither writes to the clipboard nor opens a browser.',
    'Privacy_保存削除説明':
        'Diaries, diagnosis results, settings, and the latest recording are stored on this device. Delete entries individually or use Reset. Reset also deletes recordings, quarantined corrupted data, and temporary exports. Backups are temporarily created as JSON when requested; copies saved through the share sheet cannot be deleted by this app.',
    'Google送信確認_タイトル_発言': 'Send what you said to Google?',
    'Google送信確認_本文_発言':
        'The full speech transcript and instructions for summarization, energy and Japanese conversation-skill analysis, and output formatting will be sent to Google Search (AI Mode), provided by Google LLC, to perform that analysis. Your speech may contain personal information such as names, health information, or events from your life. The request may be stored in search history or associated with the Google Account currently signed in.',
    'Google送信確認_タイトル_日記': 'Send your diary records to Google?',
    'Google送信確認_本文_日記':
        'Dates, energy scores, conversation-skill scores from saved diary entries, and trend-analysis instructions will be sent to Google Search (AI Mode), provided by Google LLC, to obtain advice based on diary trends. These records may contain personal information. The request may be stored in search history or associated with the Google Account currently signed in.',
  };

  static const _vi = <String, String>{
    '設定': 'Cài đặt',
    'その他': 'Khác',
    'リセット': 'Đặt lại',
    '会話をリセットしますか？': 'Đặt lại cuộc trò chuyện?',
    '会話リセット_確認':
        'Thao tác này sẽ xóa âm thanh đã ghi và nội dung đã chuyển thành văn '
        'bản, rồi quay về trạng thái ban đầu. Không thể hoàn tác.',
    '言語': 'Ngôn ngữ',
    'アプリの表示言語を変更できます。': 'Bạn có thể đổi ngôn ngữ hiển thị.',
    'スタートアップ_説明':
        'Hãy diễn đạt bằng lời những gì\nbạn đang cảm nhận và suy nghĩ.',
    '起動_操作ヒント_前': 'Nhấn giữ nút ',
    '起動_操作ヒント_後': ' trên mỗi màn hình\nđể xem hướng dẫn sử dụng',
    'ヘルプ_録音_手順1': '1️⃣ Chọn thời lượng ghi âm',
    'ヘルプ_録音_手順2': '2️⃣ Chạm nút {{icon}} để bắt đầu ghi âm',
    'ヘルプ_録音_手順3': '3️⃣ Kết thúc ghi âm',
    'ヘルプ_録音_手順3a': '♾️ Chạm lại nút {{icon}}',
    'ヘルプ_録音_手順3b': '30/45/60 Tự dừng khi hết giờ đếm ngược',
    'ヘルプ_録音_手順4': '4️⃣ Chạm nút {{icon}} để AI chẩn đoán',
    'ヘルプ_録音_手順5': '5️⃣ Sao chép kết quả và dán vào để lưu vào nhật ký',
    'ヘルプ_ダッシュボード_見出しグラフ': '<Biểu đồ>',
    'ヘルプ_ダッシュボード_グラフ1':
        'Diễn biến kỹ năng hội thoại và điểm Genki theo thời gian',
    'ヘルプ_ダッシュボード_グラフ2': 'Vuốt để di chuyển',
    'ヘルプ_ダッシュボード_グラフ3': 'Chụm/mở để phóng to/thu nhỏ',
    'ヘルプ_ダッシュボード_見出しカレンダー': '<Lịch>',
    'ヘルプ_ダッシュボード_カレンダー1': 'Chạm vào ngày để xem nhật ký của ngày đó',
    'ヘルプ_日記_手順1':
        'Nhấn giữ điểm Genki/kỹ năng hội thoại để xem kết quả chi tiết',
    'ヘルプ_日記_手順2': 'Chạm nút {{icon}} để AI đánh giá nhật ký từ trước đến nay',
    'ヘルプ_日記_手順3': 'Sao chép kết quả và dán vào để lưu thành đánh giá nhật ký',
    '次回から表示しない': 'Không hiện lại',
    'はじめる': 'Bắt đầu',
    'スタートアップ画面': 'Màn hình khởi động',
    'スタートアップ画面_説明': 'Hiện màn hình hướng dẫn khi mở ứng dụng',
    '操作': 'Thao tác',
    'シェイクで話す': 'Lắc để nói',
    'シェイクで話す_説明': 'Lắc thiết bị để chuyển sang tab Nói',
    '気分_最悪': 'Không khỏe chút nào',
    '気分_いまいち': 'Không ổn lắm',
    '気分_まあまあ': 'Bình thường',
    '気分_良い': 'Ổn',
    '気分_最高': 'Tuyệt vời',
    '週の開始': 'Bắt đầu tuần',
    'カレンダーの週の始まりを選べます。': 'Chọn ngày bắt đầu tuần cho lịch.',
    '日曜始まり': 'Chủ Nhật',
    '月曜始まり': 'Thứ Hai',
    'タイマー設定': 'Cài đặt hẹn giờ',
    'タイマー音': 'Âm hẹn giờ',
    '利用できる音がありません': 'Không có âm thanh nào',
    '通知音_なし': 'Không',
    '通知音_不明': 'Không rõ',
    '通知音_三連音': 'Ba âm',
    '通知音_アンティシペート': 'Anticipate',
    '通知音_ブルーム': 'Bloom',
    '通知音_カリプソ': 'Calypso',
    '通知音_チューチュー': 'Choo Choo',
    '通知音_ディセント': 'Descent',
    '通知音_ファンファーレ': 'Fanfare',
    '通知音_ラダー': 'Ladder',
    '通知音_メヌエット': 'Minuet',
    '通知音_ニュース': 'News Flash',
    '通知音_ノワール': 'Noir',
    '通知音_シャーウッド': 'Sherwood Forest',
    '通知音_スペル': 'Spell',
    '通知音_サスペンス': 'Suspense',
    '通知音_テレグラフ': 'Telegraph',
    '通知音_ティプトゥ': 'Tiptoes',
    '通知音_タイプライター': 'Typewriters',
    '通知音_アップデート': 'Update',
    '標準': 'Tiêu chuẩn',
    '録音中...': 'Đang ghi âm...',
    '考え中...': 'Đang suy nghĩ...',
    '文字起こし準備中...': 'Đang chuẩn bị nhận dạng giọng nói...',
    '声が届かなかったみたい…もう一度試してね': 'Hình như chưa nghe rõ giọng bạn... thử lại nhé',
    'もう少し長く話してから離してね': 'Nói lâu hơn một chút rồi mới thả tay nhé',
    'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね':
        'Cần quyền micro và nhận dạng giọng nói. Bật trong Cài đặt nhé',
    '音声認識が使えないみたい。ネットワークを確認してね':
        'Không dùng được nhận dạng giọng nói. Hãy kiểm tra mạng nhé',
    '録音がうまくいかなかったみたい…もう一度試してね': 'Ghi âm không thành công... thử lại nhé',
    'フリー': 'Tự do',
    '30秒': '30 giây',
    '45秒': '45 giây',
    '60秒': '60 giây',
    'どんな気分？\n教えてよ': 'Bạn cảm thấy thế nào?\nKể cho tôi nghe nhé.',
    'へぇ、そうなんだ\nもう少し聞かせて': 'Ồ, vậy à.\nKể thêm cho tôi nghe đi.',
    'なるほど\nどんなことを考えているの？': 'Ra vậy.\nBạn đang nghĩ gì?',
    'そう感じたんだね\n詳しくおしえて': 'Bạn cảm thấy vậy à.\nKể chi tiết hơn nhé.',
    'その気持ちについて\n話してみて': 'Hãy nói về\ncảm xúc đó.',
    '何がそう\n思わせたのかな？': 'Điều gì khiến bạn\nnghĩ vậy?',
    '最近の様子を\n聞かせて': 'Kể cho tôi nghe\ndạo này bạn thế nào.',
    '今の気持ちを\n言葉にしてみよう': 'Thử diễn đạt cảm xúc hiện tại\nbằng lời.',
    '思いつくままに\n話してみて': 'Cứ nói những gì\nbạn nghĩ ra.',
    '振り返りダッシュボード': 'Bảng nhìn lại',
    'ボイス日記一覧': 'Danh sách nhật ký giọng nói',
    'まだ日記がないよ。\n話してみてね。': 'Chưa có nhật ký nào.\nHãy thử nói chuyện nhé.',
    'スコアの推移': 'Xu hướng điểm số',
    'まだデータがないよ。\n話すとここに元気度が記録されるよ。':
        'Chưa có dữ liệu.\nNói chuyện để mức năng lượng được ghi lại ở đây.',
    '話す': 'Nói chuyện',
    '元気度': 'Năng lượng',
    '元気度の起点': 'Điểm gốc năng lượng',
    'ポジティブ度': 'Mức độ tích cực',
    'ストレス度': 'Mức độ căng thẳng',
    '疲労感': 'Mức độ mệt mỏi',
    '意欲': 'Động lực',
    '加減点': 'Điều chỉnh',
    '最終元気度': 'Năng lượng cuối cùng',
    '理由': 'Lý do',
    '日本語評点': 'Điểm tiếng Nhật',
    '会話力': 'Khả năng hội thoại',
    'スコアの内訳': 'Chi tiết điểm',
    'スコア内訳_説明':
        'Ước tính từ thời điểm và số ký tự nói, dùng cùng phương pháp chấm JSST như osmWashabe.',
    'スコア内訳_データなし': 'Không có dữ liệu chi tiết cho mục này (có từ các mục mới).',
    'スコア内訳_時間の利用率_定義':
        'Thời gian nói ước tính chia cho khung thời gian. '
        'Cho biết bao nhiêu phần khung thời gian có thể đã dùng để nói, dựa trên số ký tự được nhận dạng.',
    'スコア内訳_推定沈黙の割合_定義':
        'Thời gian im lặng ước tính chia cho khung thời gian. '
        'Bao gồm thời gian trước khi bắt đầu nói và khoảng trống giữa các lần nói.',
    '時間の使い方': 'Cách dùng thời gian',
    '発話枠': 'Khung thời gian',
    '秒': ' giây',
    '発話文字数': 'Số ký tự nói',
    '枠あたりの発話量': 'Lượng nói / khung',
    '字/分': ' ký tự/phút',
    '推定発話時間': 'Thời gian nói ước tính',
    '時間の利用率': 'Tỷ lệ sử dụng thời gian',
    '推定沈黙の割合': 'Tỷ lệ im lặng ước tính',
    '長い沈黙（4秒以上）': 'Khoảng im lặng dài (≥4s)',
    '回': ' lần',
    'JSST 1〜2': 'JSST 1–2',
    'JSST 3〜4': 'JSST 3–4',
    'JSST 5〜6': 'JSST 5–6',
    'JSST 7〜': 'JSST 7+',
    'キャリブレーション（開発者）': 'Hiệu chỉnh (Nhà phát triển)',
    '参考レベルが算出できませんでした。キャリブレーションは利用できません。':
        'Không thể tính cấp độ tham chiếu. Không thể sử dụng hiệu chỉnh.',
    '補正係数': 'Hệ số hiệu chỉnh',
    '評価傾向': 'Xu hướng đánh giá',
    '学習回数': 'Số lần học',
    '補正後レベル': 'Cấp độ sau hiệu chỉnh',
    '自己評価を入力 (JSST 1–10)': 'Nhập tự đánh giá (JSST 1–10)',
    '適用': 'Áp dụng',
    '甘め': 'Dễ dãi',
    '辛め': 'Nghiêm khắc',
    'ヘルプ': 'Trợ giúp',
    'バージョン %@ (%@)': 'Phiên bản %@ (%@)',
    'ヘルプ紹介文':
        'Ứng dụng giúp cải thiện khả năng hội thoại tiếng Nhật (độ trôi chảy…). '
        'Trong khi ứng dụng chị em osmWashabe chú trọng việc nói liên tục '
        '45-60 giây mà không cần tìm câu trả lời "đúng", thì osmGenki? '
        'chú trọng việc vừa nói vừa tìm câu trả lời. '
        'Những gì bạn thấy là mức năng lượng và gợi ý khả năng hội thoại — '
        'không phải giao diện chấm điểm nhiều trục đầy đủ như Washabe. '
        'Hãy thử vừa để nhiều suy nghĩ hiện lên vừa nói chuyện, '
        'trả lời câu hỏi "Bạn cảm thấy thế nào?" từ ứng dụng nhé.',
    '基本操作': 'Cơ bản',
    'help.talk.title': 'Chạm để nói',
    'help.talk.body':
        'Chạm nút mic ở giữa màn hình để nói chuyện. '
        'Chọn cách ghi âm từ "Tự do", "30 giây", "45 giây" hoặc "60 giây" '
        'bên dưới thanh công cụ.\n'
        '"Tự do" sẽ bắt đầu ghi âm khi bạn chạm, và dừng khi bạn chạm lại. '
        'Nếu chọn số giây, chỉ cần chạm 1 lần là bắt đầu ghi âm và đếm '
        'ngược; chuông sẽ reo và tự dừng khi về 0. '
        'Chạm lại trong lúc đếm ngược để tạm dừng hoặc tiếp tục.',
    'help.rally.title': 'Có thể nói tiếp',
    'help.rally.body':
        'Những gì bạn nói vào mic sẽ được nối tiếp cho đến khi bạn gửi đi. '
        'Không cần nói hết trong một lần, có thể chia làm nhiều lượt. '
        'Muốn nói lại từ đầu? Nút đặt lại sẽ xóa hết bất cứ lúc nào.',
    'help.time.title': 'Lời gợi ý ngẫu nhiên',
    'help.time.body':
        'Câu gợi ý hiện trên màn hình mic khi bạn chưa nói gì sẽ được chọn '
        'ngẫu nhiên trong nhiều mẫu khác nhau mỗi lần, không cố định, '
        'cứ thoải mái nói chuyện nhé.',
    'help.shake.title': 'Lắc để nói',
    'help.shake.body':
        'Lắc thiết bị để chuyển sang tab Nói. '
        'Bạn có thể tắt trong Cài đặt → Thao tác.',
    'Chromeとのやりとり': 'Trao đổi với Chrome AI',
    'help.chrome.step1.title': '① Trước tiên, hãy nói vào mic',
    'help.chrome.step1.body':
        'Chạm nút mic và kể về ngày hôm nay của bạn. '
        'Khi nói xong, chạm lại để dừng ghi âm.',
    'help.chrome.step2.title': '② Bấm nút máy bay để mở Chrome',
    'help.chrome.step2.body':
        'Khi nội dung đã sẵn sàng, bấm nút máy bay bên dưới. '
        'Văn bản sẽ được tự động sao chép và Chrome sẽ mở ra. '
        'Ở đó, AI sẽ tính ra mức năng lượng và khả năng hội thoại (độ trôi chảy…) của bạn.',
    'help.chrome.step3.title': '③ Sao chép câu trả lời khi nó hiện ra',
    'help.chrome.step3.body':
        'Khi Chrome hiển thị câu trả lời, hãy bấm nút sao chép (%ICON%) bên dưới để sao chép văn bản.\n'
        'Nếu không thấy nút hoặc nút không phản hồi, hãy nhấn giữ câu trả lời → "Chọn tất cả" → "Sao chép" thay thế.\n'
        'Sao chép xong thì quay lại ứng dụng này nhé.',
    'help.chrome.step4.title': '④ Bấm nút dán để lưu lại',
    'help.chrome.step4.body':
        'Quay lại ứng dụng, hãy bấm nút dán bên dưới. '
        'Nó sẽ đọc câu trả lời đã sao chép và lưu ngay vào nhật ký của bạn.',
    '振り返り': 'Nhìn lại',
    '日記をエクスポート': 'Xuất nhật ký',
    'エクスポートに失敗しました': 'Xuất thất bại',
    'エクスポートする日記がありません': 'Không có mục nhật ký để xuất',
    '日記をエクスポートしました_件数': 'Đã xuất %@ mục nhật ký.',
    '日記をエクスポートしました_件数_診断結果あり':
        'Đã xuất %@ mục nhật ký và %@ kết quả chẩn đoán.',
    '日記をインポート': 'Nhập nhật ký',
    'インポート完了': 'Hoàn tất nhập',
    '日記をインポートしました': 'Đã nhập %@ mục nhật ký.',
    '日記をインポートしました_スキップあり':
        'Đã nhập %@ mục nhật ký.\n(Đã bỏ qua %@ mục vì đã tồn tại)',
    '日記をインポートしました_すべてスキップ':
        'Cả %@ mục trong tệp đều đã có trên thiết bị này nên không thêm mục nào.',
    '診断結果をインポートしました': 'Đã nhập %@ kết quả chẩn đoán.',
    '診断結果をインポートしました_スキップあり':
        'Đã nhập %@ kết quả chẩn đoán.\n(Đã bỏ qua %@ mục vì đã tồn tại)',
    '診断結果をインポートしました_すべてスキップ':
        'Cả %@ kết quả chẩn đoán trong tệp đều đã có trên thiết bị này nên '
        'không thêm mục nào.',
    'インポートエラー': 'Lỗi nhập',
    'インポート失敗_メッセージ': 'Không thể đọc tệp: %@',
    'OK': 'OK',
    '初期化_説明':
        'Xóa toàn bộ dữ liệu trên thiết bị (nhật ký, kết quả chẩn đoán, bản ghi âm, '
        'cài đặt, v.v.) và đưa ứng dụng về trạng thái vừa mới cài đặt.',
    '初期化_確認':
        'Toàn bộ dữ liệu trên thiết bị (nhật ký, kết quả chẩn đoán, bản ghi âm, '
        'cài đặt, v.v.) sẽ bị xóa, đưa ứng dụng về trạng thái vừa mới cài đặt. '
        'Không thể hoàn tác.',
    '初期化しますか？': 'Đặt lại toàn bộ dữ liệu?',
    '初期化しました': 'Đã đặt lại toàn bộ dữ liệu',
    'キャンセル': 'Hủy',
    '初期化': 'Đặt lại toàn bộ dữ liệu',
    'データ': 'Dữ liệu',
    '削除しますか？': 'Xóa mục này?',
    '日記削除_確認': 'Nhật ký này sẽ bị xóa. Không thể hoàn tác.',
    '削除': 'Xóa',
    'help.dashboard.title': 'Bảng điều khiển',
    'help.dashboard.body':
        'Chạm biểu tượng biểu đồ để xem xu hướng năng lượng và điểm khả năng '
        'hội thoại trên lịch và đồ thị. Khi có nhiều mục ghi, biểu đồ ban '
        'đầu hiển thị toàn bộ lịch sử. Chụm hai ngón để phóng to hoặc thu '
        'nhỏ, và kéo để cuộn trái phải.',
    'help.diary.title': 'Nhật ký giọng nói',
    'help.diary.body':
        'Sau khi dán kết quả từ Chrome, nó sẽ được lưu trên thiết bị dưới '
        'dạng nhật ký kèm năng lượng và điểm khả năng hội thoại. '
        'Bạn có thể xem lại các mục cũ từ danh sách bất cứ lúc nào.',
    'help.review.title': 'Xin lời khuyên về nhật ký',
    'help.review.body':
        'Nhấn nút "Chẩn đoán" ở đầu danh sách nhật ký giọng nói để nhận '
        'lời khuyên dựa trên các ghi chép từ trước đến nay trong Chrome. '
        'Sao chép lời khuyên trong Chrome rồi bấm nút dán để lưu lại và '
        'đọc ngay. Bạn có thể xem lại các kết quả đã lưu bất cứ lúc nào '
        'từ nút "Xem". Câu trả lời sẽ theo ngôn ngữ hiển thị của ứng dụng.',
    '開発者モードを有効にしました': 'Đã bật chế độ nhà phát triển',
    '開発者モードを無効にしました': 'Đã tắt chế độ nhà phát triển',
    '開発者向け': 'Dành cho nhà phát triển',
    '音声認識ログ': 'Nhật ký nhận dạng giọng nói',
    '音声認識ログ_説明':
        'Hoạt động nhận dạng giọng nói gần đây được lưu trên thiết bị. '
        'Nếu ứng dụng bị đơ, hãy khởi động lại và mở Cài đặt → Nhật ký nhận dạng giọng nói.',
    '音声認識ログ_設定説明':
        'Bạn có thể xem nhật ký ở đây ngay cả sau khi ứng dụng bị đơ hoặc sập.',
    '(ログなし)': '(Không có nhật ký)',
    '再読み込み': 'Tải lại',
    'コピー': 'Sao chép',
    'コピーしました': 'Đã sao chép',
    'クリア': 'Xóa',
    '元気してる？': 'Bạn cảm thấy thế nào?',
    '送信': 'Gửi',
    '聴き直す': 'Nghe lại',
    '停止': 'Dừng',
    '貼り付け': 'Dán',
    '解析結果を読み取れなかった':
        'Không tìm thấy điểm điều chỉnh năng lượng. Hãy đảm bảo văn bản có dạng "Điều chỉnh năng lượng: +2".',
    'Chromeを開けなかった':
        'Không mở được Chrome. Hãy kiểm tra xem thiết bị đã cài trình duyệt chưa.',
    'Chrome AI解析結果_元気度のみ': 'Kết quả Chrome AI (元気度: %@)',
    'Chrome AI解析結果': 'Kết quả Chrome AI (元気度: %@ / cấp độ tiếng Nhật: %@)',
    '結果を保存しました': 'Đã lưu kết quả',
    'ヒント_送信待ち': 'Nói xong thì bấm nút máy bay để Chrome phân tích nhé.',
    'ヒント_貼り付け待ち': 'Quay lại từ Chrome thì bấm nút dán để lưu vào nhật ký nhé.',
    'アドバイス': 'Lời khuyên',
    'アドバイスを読み取れなかった':
        'Không đọc được lời khuyên. Hãy kiểm tra xem đã sao chép chưa nhé.',
    'ヒント_日記レビュー貼り付け待ち':
        'Sau khi sao chép lời khuyên trong Chrome, hãy bấm nút dán nhé.',
    '診断': 'Chẩn đoán',
    '閲覧': 'Xem',
    '診断結果': 'Kết quả chẩn đoán',
    '診断結果削除_確認': 'Kết quả chẩn đoán này sẽ bị xóa. Không thể hoàn tác.',
    'まだ診断結果がないよ。\n「診断」から日記を見てもらってね。':
        'Chưa có kết quả chẩn đoán nào.\nHãy nhấn "Chẩn đoán" để xin lời khuyên về nhật ký.',
    'プライバシー': 'Quyền riêng tư',
    'OS音声認識': 'Nhận dạng giọng nói của hệ điều hành',
    'Google AI': 'Google AI',
    '保存・削除・バックアップ': 'Lưu trữ, xóa & sao lưu',
    'Appleプライバシーポリシー': 'Chính sách quyền riêng tư của Apple',
    'Googleプライバシーポリシー': 'Chính sách quyền riêng tư của Google',
    '本アプリのプライバシーポリシー': 'Chính sách quyền riêng tư của ứng dụng này',
    '音声認識同意_タイトル': 'Xử lý bên ngoài đối với âm thanh đã ghi',
    '音声認識同意_本文':
        'Để chuyển lời nói thành văn bản, âm thanh đã ghi có thể được cung cấp cho Apple trên iOS hoặc nhà cung cấp nhận dạng giọng nói được cài đặt trên thiết bị Android (như Google hoặc nhà sản xuất thiết bị), và có thể được xử lý trên đám mây. Nhà cung cấp xử lý âm thanh nhằm chuyển lời nói thành văn bản. Đôi khi ứng dụng dùng nhận dạng ngoại tuyến. Bạn có thể rút lại đồng ý bất cứ lúc nào tại Cài đặt → Quyền riêng tư. Nếu từ chối hoặc rút lại, ghi âm và nhận dạng giọng nói sẽ không bắt đầu.',
    '音声認識同意_本文_iOS':
        'Để tạo bản ghi lời nói, âm thanh ghi âm được gửi đến dịch vụ nhận dạng giọng nói tích hợp trên hệ điều hành (Speech Recognition của Apple). Có thể được xử lý trên máy chủ của Apple. Bạn có thể rút lại đồng ý bất cứ lúc nào tại Cài đặt → Quyền riêng tư. Nếu từ chối hoặc rút lại, ghi âm và nhận dạng giọng nói sẽ không bắt đầu. Áp dụng điều khoản và chính sách quyền riêng tư của Apple.',
    '音声認識同意_本文_Android':
        'Để tạo bản ghi lời nói, âm thanh ghi âm được gửi đến dịch vụ nhận dạng giọng nói tích hợp trên hệ điều hành. Nếu nhận dạng thất bại, ứng dụng chuyển sang mô hình Vosk ngoại tuyến trên thiết bị và không gửi gì ra ngoài. Bạn có thể rút lại đồng ý bất cứ lúc nào tại Cài đặt → Quyền riêng tư. Nếu từ chối hoặc rút lại, ghi âm và nhận dạng giọng nói sẽ không bắt đầu.',
    '同意しない': 'Từ chối',
    '同意する': 'Đồng ý',
    '同意を撤回': 'Rút lại đồng ý',
    '撤回する': 'Rút lại',
    '未同意': 'Chưa đồng ý',
    '同意中': 'Đã đồng ý',
    '音声認識同意_撤回確認タイトル': 'Rút lại đồng ý nhận dạng giọng nói?',
    '音声認識同意_撤回確認本文':
        'Ghi âm và nhận dạng giọng nói sẽ bị tắt cho đến khi bạn đồng ý lại.',
    'Privacy_音声認識説明_iOS':
        'Âm thanh ghi âm được gửi đến dịch vụ nhận dạng giọng nói tích hợp trên hệ điều hành. Mục đích là tạo bản ghi lời nói. Ứng dụng hỏi sự đồng ý trước lần đầu sử dụng; các tính năng không cần nhận dạng giọng nói vẫn dùng được nếu bạn từ chối. Áp dụng điều khoản và chính sách quyền riêng tư của Apple.',
    'Privacy_音声認識説明_Android':
        'Âm thanh ghi âm được gửi đến dịch vụ nhận dạng giọng nói tích hợp trên hệ điều hành, hoặc đến Vosk (mô hình ngoại tuyến trên thiết bị). Mục đích là tạo bản ghi lời nói. Ứng dụng hỏi sự đồng ý trước lần đầu sử dụng; các tính năng không cần nhận dạng giọng nói vẫn dùng được nếu bạn từ chối.',
    'Privacy_設定への案内':
        'Ngôn ngữ hiển thị và lắc để nói có thể đổi trong Cài đặt.',
    'Privacy_Google説明':
        'Trước mỗi lần phân tích lời nói hoặc xu hướng nhật ký, ứng dụng nêu rõ dữ liệu gửi cho Google LLC và mục đích rồi xin đồng ý. Nếu từ chối, ứng dụng không ghi vào bảng nhớ tạm và không mở trình duyệt.',
    'Privacy_保存削除説明':
        'Nhật ký, kết quả chẩn đoán, cài đặt và bản ghi âm gần nhất được lưu trên thiết bị. Có thể xóa từng mục hoặc dùng Đặt lại. Đặt lại cũng xóa bản ghi âm, dữ liệu lỗi đã cách ly và tệp xuất tạm thời. Bản sao lưu JSON được tạo tạm khi bạn yêu cầu; ứng dụng không thể xóa bản sao đã lưu qua bảng chia sẻ.',
    'Google送信確認_タイトル_発言': 'Gửi nội dung bạn đã nói đến Google?',
    'Google送信確認_本文_発言':
        'Toàn bộ bản chuyển lời nói thành văn bản cùng chỉ dẫn tóm tắt, phân tích mức năng lượng, kỹ năng hội thoại tiếng Nhật và định dạng đầu ra sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp để thực hiện phân tích. Lời nói có thể chứa thông tin cá nhân như tên, sức khỏe hoặc sự kiện đời sống. Yêu cầu có thể được lưu trong lịch sử tìm kiếm hoặc liên kết với Tài khoản Google đang đăng nhập.',
    'Google送信確認_タイトル_日記': 'Gửi dữ liệu nhật ký của bạn đến Google?',
    'Google送信確認_本文_日記':
        'Ngày tháng, điểm năng lượng, điểm kỹ năng hội thoại trong nhật ký đã lưu và chỉ dẫn phân tích xu hướng sẽ được gửi đến Google Search (chế độ AI) do Google LLC cung cấp để nhận lời khuyên dựa trên xu hướng nhật ký. Các bản ghi này có thể chứa thông tin cá nhân. Yêu cầu có thể được lưu trong lịch sử tìm kiếm hoặc liên kết với Tài khoản Google đang đăng nhập.',
  };

  /// カレンダーの曜日ラベル。[startMonday] が true なら月曜始まりの並びを返す。
  static List<String> weekdayLabels(
    String languageCode, {
    bool startMonday = false,
  }) {
    final sundayFirst = switch (languageCode) {
      'en' => const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      'vi' => const ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
      _ => const ['日', '月', '火', '水', '木', '金', '土'],
    };
    if (!startMonday) return sundayFirst;
    return [...sundayFirst.skip(1), sundayFirst.first];
  }

  static const _enMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// カレンダー見出し（例: "2026年7月" / "July 2026" / "Tháng 7 năm 2026"）。
  static String monthYearLabel(DateTime date, String languageCode) {
    return switch (languageCode) {
      'en' => '${_enMonthNames[date.month - 1]} ${date.year}',
      'vi' => 'Tháng ${date.month} năm ${date.year}',
      _ => '${date.year}年${date.month}月',
    };
  }

  /// 日記カードの日付表示（例: "2026年7月4日" / "July 4, 2026" / "Ngày 4 tháng 7 năm 2026"）。
  static String dateLabel(DateTime date, String languageCode) {
    return switch (languageCode) {
      'en' => '${_enMonthNames[date.month - 1]} ${date.day}, ${date.year}',
      'vi' => 'Ngày ${date.day} tháng ${date.month} năm ${date.year}',
      _ => '${date.year}年${date.month}月${date.day}日',
    };
  }

  /// 元気度グラフの横軸ラベル（短い日付）。
  static String chartAxisLabel(
    DateTime date,
    String languageCode, {
    bool showYear = false,
  }) {
    if (showYear) {
      return switch (languageCode) {
        'en' => '${_enMonthNames[date.month - 1].substring(0, 3)} ${date.year}',
        'vi' => '${date.month}/${date.year}',
        _ => '${date.year}/${date.month}',
      };
    }
    return '${date.month}/${date.day}';
  }

  /// マイク画面の待機中に表示する声かけ文。
  static const talkPromptKeys = <String>[
    'どんな気分？\n教えてよ',
    'へぇ、そうなんだ\nもう少し聞かせて',
    'なるほど\nどんなことを考えているの？',
    'そう感じたんだね\n詳しくおしえて',
    'その気持ちについて\n話してみて',
    '何がそう\n思わせたのかな？',
    '最近の様子を\n聞かせて',
    '今の気持ちを\n言葉にしてみよう',
    '思いつくままに\n話してみて',
  ];

  static final _talkPromptRandom = Random();

  static String randomTalkPromptKey() =>
      talkPromptKeys[_talkPromptRandom.nextInt(talkPromptKeys.length)];
}

extension AppStringsContext on String {
  String tr(String languageCode) => AppStrings.text(this, languageCode);

  /// 日本語会話力向上アプリとしての「問いかけ」文言用。表示言語設定に関わらず、
  /// 常に日本語で表示する（気分選択画面の挨拶、マイク画面の声かけ文など）。
  String get trJa => AppStrings.text(this, 'ja');

  String trFmt(String languageCode, List<String> args) {
    var result = tr(languageCode);
    for (final arg in args) {
      result = result.replaceFirst('%@', arg);
    }
    return result;
  }
}
