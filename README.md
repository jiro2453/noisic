# Noisic

音楽と環境音をミックスして楽しむiOSアプリ

## 概要

Noisicは、スマートフォンで再生中の音楽と環境音を同時に再生できるアプリです。
再生中の音楽のタイトル、アーティスト名、アートワークを表示しながら、お好みの環境音を選択できます。

## 機能

- 現在再生中の音楽情報を表示（タイトル、アーティスト、アートワーク）
- 6種類の環境音から選択可能
  - Night Rain (夜の雨)
  - Nature (自然の木々が触れ合う音)
  - Drive (ドライブ)
  - River (川)
  - Ocean (海)
  - Bonfire (焚き火)
- 環境音の音量調整
- 他の音楽アプリとの同時再生対応

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

### 2. Xcodeでプロジェクトを開く

```bash
open Noisic.xcodeproj
```

### 3. 音声ファイルをプロジェクトに追加

1. Xcodeでプロジェクトを開く
2. `Noisic/Resources/Sounds` フォルダに音声ファイルをドラッグ&ドロップ
3. "Copy items if needed" にチェックを入れる
4. "Add to targets" で "Noisic" にチェックを入れる

### 4. ビルドと実行

1. シミュレータまたは実機を選択
2. Command + R でビルド＆実行

## 使い方

### 基本的な使い方

1. Apple MusicやSpotifyなどで音楽を再生
2. Noisicアプリを開く
3. 上部に現在再生中の音楽情報が表示されます
4. 6つの環境音から好きなものをタップして選択
5. スライダーで環境音の音量を調整
6. Stopボタンで環境音を停止

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
