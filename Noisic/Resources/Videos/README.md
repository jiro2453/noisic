# 背景動画ファイルの配置場所

このフォルダに以下の背景動画ファイル（MP4形式）を配置してください：

## 必要なファイル

1. **night_rain.mp4** - 夜の雨の動画
2. **nature.mp4** - 自然の木々が触れ合う動画
3. **drive.mp4** - ドライブの動画
4. **river.mp4** - 川のせせらぎの動画
5. **ocean.mp4** - 海の波の動画
6. **bonfire.mp4** - 焚き火の動画

## ファイルの追加方法

### 方法1: Finderから追加

1. Xcodeでプロジェクトを開く
2. このフォルダに動画ファイルをドラッグ&ドロップ
3. "Copy items if needed" にチェック
4. "Add to targets" で "Noisic" を選択

### 方法2: Xcodeから直接追加

1. Xcodeでプロジェクト内の `Noisic/Resources/Videos` フォルダを右クリック
2. "Add Files to Noisic..." を選択
3. 動画ファイルを選択
4. "Copy items if needed" にチェック
5. "Add to targets" で "Noisic" を選択

## 動画ファイルの推奨設定

- **形式**: MP4 (H.264)
- **解像度**: 1080x1920 (縦向き) または 1920x1080 (横向き)
- **フレームレート**: 30fps または 60fps
- **ビットレート**: 5-10 Mbps
- **長さ**: 10秒以上（ループ再生されます）
- **音声**: 不要（ミュートされます）

## 動画の入手方法

### 無料動画素材サイト

- [Pexels Videos](https://www.pexels.com/videos/) - 高品質な無料動画素材
- [Pixabay Videos](https://pixabay.com/videos/) - 無料動画素材
- [Videvo](https://www.videvo.net/) - 無料・有料動画素材
- [Coverr](https://coverr.co/) - 無料の美しい動画素材

### 推奨検索キーワード

- night rain
- nature trees wind
- driving car road
- river stream water
- ocean waves
- bonfire campfire flames

**注意**: 動画のライセンスを確認し、適切に使用してください。

## トラブルシューティング

### 動画が再生されない場合

1. ファイル名が正確に一致しているか確認（拡張子含む）
2. ファイルがプロジェクトに正しく追加されているか確認
3. Build Phases > Copy Bundle Resources に動画ファイルが含まれているか確認
4. Clean Build Folder（Shift + Command + K）を実行してから再ビルド

### ファイルサイズが大きすぎる場合

動画ファイルが大きすぎる場合は、以下の方法で圧縮できます：

```bash
# ffmpegを使用して圧縮（インストール必要）
ffmpeg -i input.mp4 -vcodec h264 -acodec aac -b:v 5000k output.mp4
```

または、HandBrakeなどの動画変換ソフトを使用してください。
