# Noisic

音楽と環境音をミックスして楽しむiOSアプリ

## 概要

Noisicは、スマートフォンで再生中の音楽と環境音を同時に再生できるアプリです。
再生中の音楽のタイトル、アーティスト名、アートワークを表示しながら、お好みの環境音を選択できます。

## 機能

- **没入感のある動画背景**: 各環境音に対応した動画が背景で再生
- **スワイプで切り替え**: 左右にスワイプして環境音を変更、自動で音が切り替わる
- **現在再生中の音楽情報を表示**: タイトル、アーティスト、アートワークを表示
- **6種類の環境音から選択可能**:
  - Night Rain (夜の雨)
  - Nature (自然の木々が触れ合う音)
  - Drive (ドライブ)
  - River (川)
  - Ocean (海)
  - Bonfire (焚き火)
- **環境音の音量調整**: リアルタイムでボリューム調整
- **他の音楽アプリとの同時再生対応**: Apple Music、Spotifyなどと同時再生可能

## 必要要件

- iOS 15.0以上
- Xcode 15.0以上（開発時）

## セットアップ

### 1. 音声ファイルの準備

以下の環境音ファイル（MP3形式）を用意してください：

- `night_rain.mp3` - 夜の雨の音
- `nature.mp3` - 自然の木々が触れ合う音
- `drive.mp3` - ドライブの音
- `river.mp3` - 川のせせらぎ
- `ocean.mp3` - 海の波の音
- `bonfire.mp3` - 焚き火の音

### 2. 背景動画ファイルの準備

以下の背景動画ファイル（MP4形式）を用意してください：

- `night_rain.mp4` - 夜の雨の動画
- `nature.mp4` - 自然の木々が触れ合う動画
- `drive.mp4` - ドライブの動画
- `river.mp4` - 川のせせらぎの動画
- `ocean.mp4` - 海の波の動画
- `bonfire.mp4` - 焚き火の動画

**推奨設定**: 1080p、30fps、H.264、10秒以上（ループ再生）

**無料動画素材**: [Pexels Videos](https://www.pexels.com/videos/)、[Pixabay Videos](https://pixabay.com/videos/)

### 3. Xcodeでプロジェクトを開く

```bash
open Noisic.xcodeproj
```

### 4. メディアファイルをプロジェクトに追加

#### 音声ファイル
1. `Noisic/Resources/Sounds` フォルダに音声ファイルをドラッグ&ドロップ
2. "Copy items if needed" にチェック
3. "Add to targets" で "Noisic" を選択

#### 動画ファイル
1. `Noisic/Resources/Videos` フォルダに動画ファイルをドラッグ&ドロップ
2. "Copy items if needed" にチェック
3. "Add to targets" で "Noisic" を選択

### 5. ビルドと実行

1. シミュレータまたは実機を選択
2. Command + R でビルド＆実行

## 使い方

### 基本的な使い方

1. **音楽を再生**: Apple MusicやSpotifyなどで音楽を再生
2. **Noisicアプリを起動**: アプリを開くと自動的に最初の環境音が再生開始
3. **音楽情報の確認**: 上部に現在再生中の音楽情報（アートワーク、タイトル、アーティスト）が表示
4. **環境音を切り替え**: 左右にスワイプして好きな環境音に変更（自動で音が切り替わる）
5. **音量調整**: 下部のスライダーで環境音の音量を調整
6. **停止**: "Stop Ambient Sound" ボタンで環境音を停止

### 特徴

- **スワイプで即座に切り替え**: 画面を左右にスワイプするだけで、環境音と背景動画が同時に切り替わります
- **自動再生**: スワイプすると自動的に新しい環境音が再生開始
- **没入感のある体験**: フルスクリーン動画背景で環境音の世界に浸れます

### 注意事項

- **音楽情報の表示について**
  - Apple Musicで再生中の音楽情報は正常に表示されます
  - Spotifyなどの他のアプリの場合、情報が取得できない場合があります
  - これはiOSのセキュリティ制限によるものです

- **バックグラウンド再生**
  - 環境音はバックグラウンドでも再生を継続します
  - アプリを閉じても音楽と環境音は再生され続けます

## プロジェクト構成

```
Noisic/
├── Noisic.xcodeproj/          # Xcodeプロジェクトファイル
└── Noisic/
    ├── NoisicApp.swift         # アプリのエントリーポイント
    ├── Views/
    │   └── ContentView.swift   # メインUI
    ├── Models/
    │   ├── AmbientSound.swift  # 環境音のモデル
    │   └── MusicInfo.swift     # 音楽情報のモデル
    ├── Managers/
    │   ├── AudioSessionManager.swift    # オーディオセッション管理
    │   ├── AudioManager.swift           # 環境音再生管理
    │   └── MusicInfoReader.swift        # 音楽情報取得
    ├── Resources/
    │   └── Sounds/             # 環境音ファイル配置場所
    ├── Assets.xcassets/        # アセットカタログ
    └── Info.plist              # アプリ設定
```

## 技術詳細

### オーディオセッションの設定

アプリは `.playback` カテゴリで `.mixWithOthers` オプションを使用しており、
他の音楽アプリと同時に再生できるようになっています。

```swift
try audioSession.setCategory(
    .playback,
    mode: .default,
    options: [.mixWithOthers]
)
```

### 音楽情報の取得

`MPMusicPlayerController.systemMusicPlayer` を使用して、
システムで再生中の音楽情報を取得しています。

### 環境音の再生

`AVAudioPlayer` を使用して環境音をループ再生しています。

## カスタマイズ

### 環境音の追加

1. `Noisic/Models/AmbientSound.swift` を編集
2. 新しいケースを追加
3. 対応する音声ファイルを `Resources/Sounds/` に配置

### UIのカスタマイズ

`Noisic/Views/ContentView.swift` でUIをカスタマイズできます。
シンプルなSwiftUIで構成されているため、簡単に変更可能です。

## ライセンス

このプロジェクトは個人使用を目的としています。

## トラブルシューティング

### 音楽情報が表示されない

- Apple Musicで音楽を再生していることを確認してください
- 設定アプリで「メディアとApple Music」の権限を確認してください

### 環境音が再生されない

- 音声ファイルが正しく追加されているか確認してください
- ファイル名が正しいか確認してください（例：`night_rain.mp3`）
- デバイスのボリュームを確認してください

### ビルドエラーが発生する

- Xcodeのバージョンを確認してください（15.0以上推奨）
- Clean Build Folder（Shift + Command + K）を実行してください
