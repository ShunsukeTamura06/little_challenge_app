# Android 配信（Google Play）手順

このプロジェクトは iOS（TestFlight）配信済みです。Android でも配信できるよう、以下の手順で準備・ビルド・申請を進めてください。

## 1) アプリIDの確定（重要）
- 現在の Android 設定：
  - `applicationId`: `com.example.little_challenge_app`
  - `namespace`: `com.example.little_challenge_app`
- iOS の Bundle ID は `com.ssk.littlechallengeapp` です。Android でも同一系の `com.ssk.littlechallengeapp` を推奨します。
- 確定後に以下を変更します：
  - `android/app/build.gradle.kts` の `applicationId` と `namespace`
  - Kotlin パッケージの移動と宣言変更：
    - ディレクトリを `android/app/src/main/kotlin/com/example/little_challenge_app/` から `android/app/src/main/kotlin/com/ssk/littlechallengeapp/` へ移動
    - `MainActivity.kt` 先頭の `package` を `com.ssk.littlechallengeapp` に変更

> 注意: Play Console で一度公開したアプリIDは後から変更できません。

## 2) 署名鍵（Keystore）の作成と登録
- 署名情報ファイルのサンプルを追加済み：`android/key.properties.sample`
- 実ファイル `android/key.properties` は Git 管理対象外です（安全のため未コミット）。

### Keystore 作成
```
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
- パスワードは控えて安全に保管してください。

### key.properties を作成
- `android/key.properties.sample` をコピーして `android/key.properties` を作成し、実値で置き換えます：
```
storeFile=/absolute/path/to/your/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

Gradle は `key.properties` が存在する場合のみ release 署名を適用します（存在しない場合はローカル実行のために debug 署名にフォールバック）。

## 3) バージョンとラベル
- バージョンは `pubspec.yaml` の `version: x.y.z+build` に従います。
- Play へ再アップロードする度に `build`（= versionCode）を増やしてください（例: `1.0.0+3`）。
- 表示名（ラベル）は `android/app/src/main/AndroidManifest.xml` の `android:label` です。必要なら iOS と同じ文言に合わせてください。

## 4) リリースビルド
- 依存関係取得：`flutter pub get`
- App Bundle（推奨）：`flutter build appbundle --release`
  - 出力: `build/app/outputs/bundle/release/app-release.aab`
- APK（任意）：`flutter build apk --release`

## 5) Google Play Console 設定
1. 新しいアプリを作成（アプリ名・言語を設定）。
2. 「アプリの署名」で「Google Play アプリ署名（推奨）」を選択。
3. 「アプリの配布」>「内部テスト」を作成し、`app-release.aab` をアップロード。
4. テスター（メール）を追加し、リンクを配布して動作確認。
5. ストアの掲載情報を入力：
   - アプリ名、短い説明、完全な説明（日本語）
   - アイコン（512×512）、Feature グラフィック（1024×500）
   - スクリーンショット（スマートフォン）
6. コンテンツのレーティングアンケート、ターゲットユーザー、広告の有無、プライバシーポリシー URL を登録。
7. データ安全性（Data Safety）を正しく申告（カレンダー権限の用途など）。
8. 問題なければ「内部テスト」→「公開」、その後「オープンテスト」や「本番リリース」へ段階的に拡大。

## 6) 権限とプラグインの注意点
- 本アプリは `add_2_calendar` を使用しています。Android ではカレンダー権限（`READ_CALENDAR` / `WRITE_CALENDAR`）が必要です。
- 多くの場合、プラグイン経由でマニフェストにマージされますが、実機での動作と許可ダイアログの挙動を確認してください。

## 7) トラブルシュート
- 署名エラー: `key.properties` のパスやパスワード、`storeFile` の絶対パスを再確認。
- バージョンコード重複: `pubspec.yaml` の `+` 以降（build）をインクリメント。
- target/min SDK の警告: 本プロジェクトは Flutter 既定値（minSdk 21、targetSdk 34 想定）を使用。

---
不明点（アプリIDの最終決定、ストア文言、スクリーンショット作成など）があれば指示ください。こちらでパッケージ名のリネームと必要ファイルの更新まで対応します。
