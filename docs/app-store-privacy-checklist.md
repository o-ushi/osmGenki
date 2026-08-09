# App Storeプライバシー提出チェックリスト

## 公開前の差し替え

- [ ] App Store ConnectのプライバシーポリシーURLを公開済みの `docs/privacy-policy-ja.md`（またはそのHTTPS公開先。現状は下記Googleドキュメント）のURLに差し替える
      https://docs.google.com/document/d/1vUD5NWUC8ta0j-VAl4UkXCy-nA4zIRiTdDgkR-9jcyo/edit?usp=sharing
- [ ] Googleドキュメントの共有設定が「リンクを知っている全員が閲覧可」であることを再確認（審査担当者が編集権限なしで開けるように。確認済み: 2026-07-19時点でreader/anyone）
- [ ] `docs/privacy-policy-ja.md` の問い合わせ先を実在するサポート窓口（メール等）へ更新する
- [ ] App Store ConnectのサポートURLを設定する

## App Privacy回答案（提出時に実装最新版と照合）

- User Content > Audio Data（音声データ）: 収集する。本人（アカウント）への紐付けなし。追跡目的の使用なし。目的はApp Functionalityのみ（OS音声認識による文字起こし）。
- User Content > Other User Content（発話の文字起こし全文・日記本文・元気度/会話力スコア）: 収集する。本人への紐付けなし。追跡目的の使用なし。目的はApp Functionalityのみ（ユーザーが都度同意した場合に限りGoogle検索[AIモード]へ送信）。
- Identifiers / Usage Data / Diagnostics: 未使用。広告ID、独自アカウントID、分析SDK、クラッシュ報告SDKをアプリ独自実装では使用していない（`pubspec.yaml`にFirebase/Analytics/Ads系パッケージなしを確認済み）。
- Location / Contact Info / Health / Financial Info / Purchases / Browsing History / Search History / Contacts: 未収集（該当する権限・実装なし）。
- Tracking: 追跡目的の利用、他社データとの結合、広告は行わない。ATTを要求しない。

「収集」のApple定義は、端末外へ送信され、事業者または第三者が一時的処理を超えて保持する場合を含み得ます。App Store Connectでは保守的かつ実態どおりに回答してください。

## 審査ノート案

> バージョン1.0.0(4)の音声認識・外部送信同意を、それぞれの初回操作前に表示します。録音開始前にはOS音声認識（iOS: Apple、Android: 端末設定の音声認識事業者）へ録音音声を提供する旨を開示し、明示的な同意を取得します。同意内容は版番号付きで端末に保存し、「設定 → プライバシー」からいつでも撤回できます。未同意または撤回後は録音・音声認識を開始しません。
>
> 発話解析・日記診断の送信操作ごとに、Google LLCが提供するGoogle検索（AIモード）への送信内容（発話全文または日記の日付・スコア、解析指示）、送信目的、個人情報が含まれる可能性を開示し、都度同意を確認します。「同意しない」を選んだ場合、クリップボードへの書き込みおよびブラウザ起動は行いません。本アプリは外部AI APIへ直接データを送信せず、Google検索（AIモード）はユーザー操作でブラウザを開く形でのみ利用します。APIキーや自社サーバーへの送信は行いません。
>
> 「設定 → プライバシー」画面には、本アプリのプライバシーポリシー本文、Apple / Googleの関連ポリシーへのリンク、OS音声認識の同意状態表示と撤回操作、および「初期化」（全データ削除）を掲載しています。「初期化」は日記、診断結果、設定、同意記録、直近の録音、音声認識ログを削除します。同じ「初期化」操作は「設定 → 振り返り」からも行えます。
>
> アプリはiPhone・iPad対応（Universal）、縦向き固定です。

## 提出直前

- [ ] 初回起動、音声認識同意の許可/拒否/撤回/再同意、Google送信同意の許可/拒否、全データ削除を実機（iPhone・iPad双方）で確認
- [ ] 通信プロキシまたはNetwork Instrumentsで、未同意・拒否時にGoogle/音声認識サービスへ送信されないことを確認
- [ ] ArchiveのPrivacy Reportで収集項目・Required Reason API宣言を確認
- [ ] App Store Connectの回答を公開ポリシーとアプリ内文言（`lib/l10n/app_strings.dart`）に一致させる
- [ ] 3言語（日本語・英語・ベトナム語）の同意文・リンクを実機確認
- [ ] iPhone・iPad実機で縦向き固定であることをArchiveで確認（`TARGETED_DEVICE_FAMILY = "1,2"`、`UISupportedInterfaceOrientations`はPortraitのみ、iPad個別オーバーライドなし）
- [ ] Apple/Googleのポリシーリンク、本アプリのプライバシーポリシーリンクが審査ネットワークから開くことを確認

## PrivacyInfo.xcprivacy

Runner（アプリ独自コード）について、現時点で根拠を確認できないRequired Reason API宣言は追加していません。提出に使うXcodeのArchive Privacy Reportと、CocoaPods経由で取り込まれる各プラグイン（shared_preferences、path_provider、url_launager等）が同梱するPrivacyInfo.xcprivacyの内容を照合し、Runner自身が対象APIを使用していると確認できた場合のみ、該当理由コードを追加してください。

## ビルド設定（2026-07-19時点）

- iOS対象: iPhone・iPad（Universal, `TARGETED_DEVICE_FAMILY = "1,2"`）。以前iPhone専用（`= 1`）に変更した際、既存バージョンがiPad対応済みだったためApp Store Connectへのアップロードがエラーコード90101で拒否された経緯があり、Universalに戻した。
- iOS向き: Portraitのみ（iPad個別オーバーライドなし、iPadでも縦向き固定）
- Android: `AndroidManifest.xml`の`MainActivity`に`android:screenOrientation="portrait"`、`<supports-screens>`で`largeScreens`/`xlargeScreens`を`false`にしてタブレット配信を除外。Google PlayはAppleと異なり「既存対応デバイスの削減」を理由にアップロードを拒否しないため、iOSと同じ問題は起きない。
