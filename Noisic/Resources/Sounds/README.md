# 環境音ファイルの配置場所

このフォルダに以下の環境音ファイル（MP3形式）を配置してください：

## 必要なファイル

1. **night_rain.mp3** - 夜の雨の音
2. **nature.mp3** - 自然の木々が触れ合う音
3. **drive.mp3** - ドライブの音
4. **river.mp3** - 川のせせらぎ
5. **ocean.mp3** - 海の波の音
6. **bonfire.mp3** - 焚き火の音

## ファイルの追加方法

### 方法1: Finderから追加

1. Xcodeでプロジェクトを開く
2. このフォルダに音声ファイルをドラッグ&ドロップ
3. "Copy items if needed" にチェック
4. "Add to targets" で "Noisic" を選択

### 方法2: Xcodeから直接追加

1. Xcodeでプロジェクト内の `Noisic/Resources/Sounds` フォルダを右クリック
2. "Add Files to Noisic..." を選択
3. 音声ファイルを選択
4. "Copy items if needed" にチェック
5. "Add to targets" で "Noisic" を選択

## 音声ファイルの推奨設定

- **形式**: MP3
- **ビットレート**: 128kbps - 192kbps
- **サンプリングレート**: 44.1kHz
- **チャンネル**: モノラルまたはステレオ
- **ループ可能**: はい（シームレスにループできる音源が望ましい）

## 音声ファイルの入手先（例）

無料の環境音を入手できるサイト：

- [Freesound](https://freesound.org/) - クリエイティブ・コモンズライセンス
- [YouTube Audio Library](https://www.youtube.com/audiolibrary) - 無料音源
- [Zapsplat](https://www.zapsplat.com/) - 無料・有料音源

**注意**: 音声ファイルのライセンスを確認し、適切に使用してください。

## トラブルシューティング

### 音が再生されない場合

1. ファイル名が正確に一致しているか確認（拡張子含む）
2. ファイルがプロジェクトに正しく追加されているか確認
3. Build Phases > Copy Bundle Resources に音声ファイルが含まれているか確認
