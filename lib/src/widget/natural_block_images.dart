// 【解説】 読む順番 12/12: :@image(URL):@ と書いた run を、文字の代わりに画像で描く部品。
// 【解説】 ActionSpanBuilder(3)の形をした builder を、NaturalBlockActions.buildSpan に渡して使う。
// 【解説】 ネットワーク上の画像だけを描き、ファイルや相対パスは描かずに文字のまま残す。
import 'package:flutter/widgets.dart';

import 'natural_block_theme.dart';

// 【解説】 画像の置き場所の種類。
enum ImageSourceKind { network, file, relative }

// 【解説】 abstract final class: インスタンスを作れず(abstract)、継承も実装もできない(final)。
// 【解説】 static なものだけを入れる「名前空間」として使っている。
abstract final class NaturalBlockImages {
  // 【解説】 r'...' は raw 文字列(\ をそのまま書ける)。image( と ) に挟まれた部分を取り出す正規表現。
  // 【解説】 dotAll: true で . が改行にも一致する。
  static final RegExp _pattern = RegExp(r'^image\((.+)\)$', dotAll: true);

  static InlineSpan? builder(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) {
    final url = urlOf(text);
    // 【解説】 image(...) の形でないか、ネットワーク上の画像でなければ null を返し、普通の文字として描かせる。
    if (url == null || kindOf(url) != ImageSourceKind.network) return null;

    // 【解説】 画像の大きさを、その run の文字の大きさに合わせるための倍率。
    // 【解説】 Image の scale は「大きいほど小さく描く」ので、基準 ÷ 今の大きさになる。
    final size = style.fontSize ?? theme.baseFontSize;
    final scale = theme.baseFontSize / size;

    // 【解説】 WidgetSpan: 文章の途中にウィジェットを埋め込む InlineSpan。
    return WidgetSpan(
      // 【解説】 行の中で、画像を文字の上下中央に揃える。
      alignment: PlaceholderAlignment.middle,
      child: Image.network(
        url,
        scale: scale,
        semanticLabel: url,
        // 【解説】 読み込みに失敗したら、元の文字をそのまま出す。
        errorBuilder: (context, error, stackTrace) => Text(text, style: style),
        // 【解説】 読み込み中(progress が null でない間)は、文字1つ分の空きを取っておく。
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : SizedBox(height: size, width: size),
      ),
    );
  }

  // 【解説】 ?. は「左が null なら、そこで止めて null」。一致しなければ null を返す。
  // 【解説】 group(1) は正規表現の1つ目の ( ) に一致した部分(URL)。
  static String? urlOf(String text) =>
      _pattern.firstMatch(text.trim())?.group(1)?.trim();

  // 【解説】 C: のような、Windows のドライブ名で始まるかを見る正規表現。
  static final RegExp _driveLetter = RegExp(r'^[A-Za-z]:');

  // 【解説】 置き場所の種類を、文字列の形だけから判断する。
  static ImageSourceKind kindOf(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return ImageSourceKind.relative;

    // 【解説】 \\server\... の形(Windows の共有フォルダ)、ドライブ名、/ で始まる絶対パスはファイル。
    if (trimmed.startsWith(r'\\')) return ImageSourceKind.file;
    if (_driveLetter.hasMatch(trimmed)) return ImageSourceKind.file;
    if (trimmed.startsWith('/')) return ImageSourceKind.file;

    // 【解説】 tryParse は、読めなければ例外ではなく null を返す。
    final uri = Uri.tryParse(trimmed);
    // 【解説】 http: などのスキームがあれば、file: ならファイル、それ以外はネットワーク。
    if (uri != null && uri.hasScheme) {
      return uri.scheme == 'file'
          ? ImageSourceKind.file
          : ImageSourceKind.network;
    }
    return ImageSourceKind.relative;
  }
}
