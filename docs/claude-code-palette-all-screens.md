# osmGenki — 全画面カラーを osmGradus と同一にする作業指示書

このファイルは、Claude Code に **全画面の色彩を osmGradus と揃える作業** をさせるためのプロンプトです。

## 使い方（人間 → Claude Code）

Claude Code に、次のように指示してください。

```text
docs/claude-code-palette-all-screens.md を読んで、書いてある通りに実施して。
完了後は実施内容の要約だけ報告して。
```

段階的に進めたい場合:

```text
docs/claude-code-palette-all-screens.md の「作業手順」1（調査）だけ実施して。
コード変更はしない。ヒット一覧だけ報告して。
```

```text
docs/claude-code-palette-all-screens.md の「作業手順」2〜4（AppColors＋ダークモード切断＋SettingsPage）だけ実施して。
境界を越えないこと。完了後は要約だけ報告して。
```

```text
docs/claude-code-palette-all-screens.md の残り（他サブ画面＋メイン残滓＋再スキャン）を実施して。
完了後は要約だけ報告して。OSダークでも設定が黒くならないことも確認結果に含めて。
```

### 共通ルール

- このファイルに書かれた範囲以外のリファクタ・機能追加はしない
- 既存のコーディングスタイル・命名・多言語（JA/EN/VI）方針に従う
- 不要なドキュメント追加・コミットはしない（明示指示がない限り）
- 色変更に付随する最小限以外のレイアウト／機能変更はしない
- 作業ルートは本リポジトリ（`osm_genki/`）とする

---

## 目的

osmGenki の **全画面・全構成要素の色**を、osmGradus の固定パレットと **見た目として同じ**にする。

### 現状の問題（繰り返さないこと）

メイン（scene `#3D5993` + パステル枠カード）はおおむね osmGradus 寄りだが、設定・ヘルプ等のサブ画面は別系統のまま残っている。

具体例（現状）:

- 設定カード背景が `Colors.white`（Gradus はクリーム `cardFill` `#FFFAF2`）
- 見出しが `kLabelGray` `#6C6C70`（Gradus は `#61616B`）
- 本文が `Colors.black` / `Colors.black54` / `ThemeData` 依存
- `GenkiSubpageScaffold` の AppBar 前景が `Colors.black`
- `genki_help_sheet.dart` だけ局所的に Gradus 色をハードコード（パレット未統一）

### osmPod で起きた失敗（Genki でも同じ穴を塞ぐ）

osmPod では「パレット導入＋メイン適用」だけでは不十分だった。

- 設定がシステムの `Form` / 意味色のまま → **端末ダークモードで黒背景・白文字**になり、Gradus 設定と全く違った
- 受け入れの確認は **端末をダークにした状態**で設定画面を開くこと（ライト端末だけでは合格にしない）
- 対策の必須セット:
  1. アプリ入口で外観をライト固定（OS ダークに追従しない）
  2. サブページ骨格で背景・文字・カードをパレット明示
  3. `Colors.white` カードや `Colors.black` 本文をやめて `cardFill` / `textOnCard*` にする（白カードのままライト固定しても Gradus ではない）

完了条件は **メイン以外も含め、全画面が同一パレット準拠**であること。部分適用は不可。

例: 設定画面なら、osmGradus の設定画面と同じ色彩（背景 `#F2F2F7`、クリームのセクションカード、見出し・本文の固定文字色）。端末がダークモードでもこの見た目のまま。

---

## 絶対ルール

1. **色だけ**直す。レイアウト・文言・機能・ナビゲーション・ビジネスロジックは変えない。
2. ユーザー向けのテーマ切替は作らない／復活させない。色は固定（現状どおり）。
3. 色の唯一のソースを osmGradus 型の `AppPalette` / `AppColors.current` に一本化する。
4. 画面ごとに「どの面の上か」を判定し、対応トークンだけ使う。
5. `Colors.black` / `Colors.white` / `Colors.black54` / `Theme.of(context).colorScheme.*` を **面の色として安易に使わない**（例外は下記）。
6. **端末ダークモードに追従しない。** `MediaQuery.platformBrightness` / `ThemeMode.system` / 親の dark `ThemeData` でサブページや設定カードの色が変わってはならない。
7. 完了条件は「全 screen / 関連 widget がパレット準拠」かつ「OS ダークでも設定が Gradus 同色」であること。

---

## 参照（必須・先に読む）

| 内容 | パス |
|------|------|
| パレット定義（正） | `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/lib/theme/app_colors.dart` |
| アプリ Theme | `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/lib/theme/app_theme.dart` |
| サブページ骨格 | `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/lib/widgets/osm_subpage_scaffold.dart` |
| サブページ Theme | `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/lib/theme/surface_theme.dart` |
| 設定セクション見た目 | `/Users/osam/Developer/com.osamushikubo/osmGradus ALL/osm_gradus/lib/widgets/settings_section.dart` |
| Genki 現状テーマ定数 | `lib/theme/app_theme.dart` |
| Genki 現状シーン／枠 | `lib/theme/appearance_resolver.dart` / `lib/notifiers/app_appearance.dart` |
| Genki サブページ骨格 | `lib/widgets/genki_subpage_scaffold.dart` |
| Genki 設定（未揃いの典型） | `lib/screens/settings_page.dart` |
| osmPod での同趣旨対応（参考） | `/Users/osam/Developer/com.osamushikubo/osmPod ALL/osmPod/docs/claude-code-palette-all-screens.md` および `Services/AppPalette.swift` の `osmSubpageListChrome` / `.preferredColorScheme(.light)` |

同じスタック（Flutter）なので、Gradus の `AppColors` / `SurfaceTheme` / `OsmSubpageScaffold` / `SettingsSection*` の構造を **移植・簡略移植してよい**。見た目規則が同一ならクラス名は Genki 側の既存名（`GenkiSubpageScaffold` 等）を維持してよい。

---

## 面モデル（osmGradus と同じ）

| 面 | 背景 | 主文字 | 副文字 | 用途 |
|---|---|---|---|---|
| scene | `scene` (`#3D5993`) | `textOnScenePrimary` | `textOnSceneSecondary` | ホーム／気分選択／スタートアップ／ダッシュボード等のメイン背景上 |
| subpage | `subpageBackground` (`#F2F2F7`) | `textOnSubpagePrimary` | `textOnSubpageSecondary` | 設定・ヘルプ・プライバシー・日記一覧などのサブ画面全体 |
| card | `cardFill` (`#FFFAF2`) | `textOnCardPrimary` | `textOnCardSecondary` | 設定セクションカード／日記カード／フレームカード |
| accent | `accentColor` (`#007AFF`) | `onAccent` | — | ボタン・選択・チェック |
| card chrome | `cardBorder` / `cardAccent` | — | — | 枠線・左ストライプ |

固定値（確認用）:

- scene `#3D5993`
- subpageBackground `#F2F2F7`
- cardFill `#FFFAF2`
- cardBorder `#F5C799`
- cardAccent `#FF9933`
- accentColor `#007AFF`
- onAccent `#FFFFFF`
- textOnScenePrimary `#FFFFFF` / Secondary `#B3FFFFFF`
- textOnSubpage/Card Primary `#1A1A1F` / Secondary `#61616B`

---

## 禁止（面の色として）

次を背景・文字・区切り・カード塗りに使わない。見つかったらパレットに置換:

- `Colors.black` / `Colors.black87` / `Colors.black54` / `Colors.white`（面の本文・カード背景としての使用）
- `Colors.grey` / `Colors.grey.shade*`
- `kLabelGray` (`#6C6C70`) → `textOnSubpageSecondary` / `textOnCardSecondary` (`#61616B`)
- `kInactiveGray` を区切りに使う場合 → `cardBorder`（または Gradus 同等の薄い cardBorder）
- 設定カードの `Colors.white` → `cardFill`
- `Theme.of(context).colorScheme.onSurface` / `surface` への暗黙依存（サブページでは `SurfaceTheme` 相当で明示）
- `ColorScheme.fromSeed` 任せの文字色・面色（seed は accent 用に残してよいが、画面の面はパレット明示）
- `ThemeMode.system` / `platformBrightness` に応じて scaffold・カード・本文色を切り替える分岐（シーンも昼夜で変えない。Gradus / 現行 Genki 方針どおり固定）

### 例外（セマンティックで残してよい）

- `kRecordingColor`（録音中の赤 `#FF3B30`）
- `kPasteReadyColor`（貼り付け待ち緑 `#34C759`）
- 破壊的アクションの赤（`Colors.red`）
- ヘルプ内の機能説明アイコン色（orange / blue / teal 等の**意味色アイコン**）。ただし周囲の背景・本文はパレット化
- スワイプ削除背景など、既存の destructive UI
- チャート／スコア可視化で色がデータの意味を持つ場合（ただし周囲の scaffold / カード枠はパレット）

---

## 実装方針（Flutter）

### A. パレットを一本化する（必須）

osmGradus `app_colors.dart` に合わせて、例えば次を導入・整理する:

- `lib/theme/app_colors.dart` … `AppPalette.flatDefault` + `AppColors.current`
- （推奨）`lib/theme/surface_theme.dart` … subpage / card 用 `ThemeData`
- 既存 `lib/theme/app_theme.dart` の `kSubpageBackground` / `kSystemBlue` 等は、最終的にパレット参照へ寄せるか、パレットの薄いエイリアスにする（二重定義を残さない）
- `AppearanceResolver` / `appAppearance` の scene・pastelFrame・accent も **同じ定数**を参照する（数値のコピペ重複をやめる）

### B. ダークモード追従を断つ（必須・osmPod 教訓）

次を必ず実施する。これ無しで「色を直した」扱いにしない。

1. **`MaterialApp` 入口（`lib/main.dart`）**
   - `themeMode: ThemeMode.light`（system 追従禁止）
   - `theme:` は Gradus `AppTheme.light()` 相当の固定 light
   - `darkTheme` を用意して system に任せる構成にしない（使うなら light と同じパレットに固定し、実質差が出ないこと）
2. **`GenkiSubpageScaffold`**
   - いまの `brightness: Brightness.light` は維持・強化
   - 背景 / AppBar / 文字はすべてパレット明示（`Colors.black` / seed 任せ禁止）
   - 親が dark でも `Theme(data: SurfaceTheme.subpage(...))` で上書きし切る
   - `SystemUiOverlayStyle` もサブページは dark icons（薄い背景向け）で固定でよい
3. **設定カード**
   - `_card` の `Colors.white` を `cardFill` に置換（ライト固定だけして白カードのままは不合格）
4. **確認方法**
   - シミュレータ／実機の外観を Dark にして設定・ヘルプを開き、黒背景になっていないこと、クリームカードであることを目視確認する前提で実装する

### C. サブページ共通を Gradus 相当に揃える

`GenkiSubpageScaffold` を更新:

- 背景 / AppBar: `subpageBackground`
- タイトル・戻る・アイコン: `textOnSubpagePrimary`（`Colors.black` 禁止）
- `SurfaceTheme.subpage` 相当で ListTile / divider / textTheme を揃える

設定系は Gradus `SettingsSectionCard` 相当:

- カード塗り: `cardFill`（白禁止）
- 見出し: カード外で `textOnSubpageSecondary`
- 行テキスト: `textOnCardPrimary` / Secondary
- 区切り: `cardBorder`
- 選択チェック / Switch: `accentColor`

`settings_page.dart` 内の私有 `_card` / `_sectionHeader` / `_noteText` を、この規則に合わせて直す（共通 widget に切り出してもよい）。

### D. 画面別の適用対象（漏れなく）

最低限、次をすべて監査・修正する。

#### サブページ（subpage + card）— 今回の主戦場

- `lib/screens/settings_page.dart`
- `lib/screens/help_page.dart`
- `lib/screens/privacy_page.dart`
- `lib/screens/timer_sound_picker_page.dart`
- `lib/screens/speech_recognition_debug_log_page.dart`
- `lib/screens/diary_list_page.dart`
- `lib/screens/diary_review_list_page.dart`
- 関連: `lib/widgets/language_picker.dart`, `genki_help_sheet.dart`, `factory_reset_action.dart`, `confirm_*`, `calibration_section.dart`, `fluency_metrics_dialog.dart`, `genki_score_breakdown_dialog.dart`, `diary_review_dialog.dart` などサブ面／ダイアログ

#### メイン（scene + card）— 残滓の掃除

- `lib/screens/home_page.dart` / `mood_selection_page.dart` / `startup_screen.dart` / `dashboard_page.dart`
- `lib/widgets/genki_frame_card.dart` / `diary_card.dart` / `appearance_background_layer.dart` / `genki_toolbar.dart` / `genki_more_actions_menu.dart`
- scene 上の文字は `textOnScenePrimary` / Secondary。カード上は `textOnCard*`。`Colors.white` 直書きを可能な限りトークンへ
- `platformBrightness` 引数があっても **シーン色は変えない**（現状の `AppearanceResolver.sceneColor` 固定を維持し、パレットへ集約）

#### アプリ入口

- `lib/main.dart` の `ThemeData` を Gradus `AppTheme.light()` 相当に寄せる（scaffold は scene、明示面は各画面／SurfaceTheme）
- **`themeMode: ThemeMode.light`** で OS ダーク追従を切る（上記 B）

---

## 作業手順（この順で）

1. **現状調査**: `lib/screens` と `lib/widgets` から  
   `Colors\.(black|white|grey)|kLabelGray|kInactiveGray|kSubpageBackground|kSystemBlue|colorScheme\.(onSurface|surface)|Colors\.black54|Colors\.black87|ThemeMode\.system|platformBrightness`  
   を洗い出し、一覧化する。
2. **`AppColors` / `AppPalette` を導入**し、`AppearanceResolver`・`app_theme.dart`・`genki_help_sheet` の重複定数をそこに集約する。
3. **ダークモード追従を断つ**（`themeMode: ThemeMode.light` + `GenkiSubpageScaffold` のパレット明示）。
4. **`GenkiSubpageScaffold` + `SettingsPage` を osmGradus 設定と同じ色彩に仕上げる**（最初の完了サンプル。クリームカード必須）。
5. 同じパターンで他サブ画面・ダイアログへ横展開。
6. メイン画面の `Colors.white` / 暗黙 Theme 依存の残滓を掃除。
7. **再スキャン**: 手順 1 の禁止パターンが「例外以外ゼロ」になるまで繰り返す。
8. 変更ファイル一覧と、画面ごとの before→after（どのトークンにしたか）を短く報告。報告に「OS ダークでも設定が黒くならないこと」を明記する。

---

## 受け入れ基準（全部満たすこと）

- [ ] 設定画面の背景が `#F2F2F7`、セクションがクリームカード `#FFFAF2`、見出しが `#61616B`、本文が `#1A1A1F`
- [ ] **端末／シミュレータを Dark にした状態でも**、設定・ヘルプが黒背景にならず上記のまま
- [ ] ヘルプ・プライバシー・日記一覧・タイマー音選択・デバッグログ等も同じ subpage/card 規則
- [ ] メインは scene `#3D5993` + カード `#FFFAF2` / 枠 `#F5C799` / ストライプ `#FF9933`（壊さない・むしろトークン化）
- [ ] `ThemeMode.system` や `platformBrightness` で面の色が切り替わらない
- [ ] `lib/screens` / `lib/widgets` に禁止パターンの残存がない（セマンティック例外を除く）
- [ ] 機能・レイアウト差分は意図的な色変更に付随する最小限のみ
- [ ] 既存テストがあれば色変更で壊れたものを最小修正（テスト追加は必須ではない）

---

## やらないこと

- 新テーマエンジン、動的テーマ、アセット差し替え、アイコン刷新
- ユーザー向け「カラーテーマ」「見た目」設定の復活
- 「ライト固定だけしてカードは白のまま」で完了扱いにすること
- ドキュメント大量追加（本ファイル以外）
- Gradus 固有機能（レイヤー色 `kLayerColors` 等）の不要な持ち込み。Genki にレイヤー概念が無いなら `layerColors` は省略してよい（他トークンは同一）

---

## 開始時の指示（Claude Code 向け）

まず調査結果（禁止パターンのヒット一覧）を出し、次に `AppColors` 整備とダークモード切断、次に `SettingsPage` から実装せよ。人間が「このファイルを読んで実施」とだけ言った場合は、上記「作業手順」1〜8を最後まで実施する。
