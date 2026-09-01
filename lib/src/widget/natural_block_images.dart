// 【解説】[番外2] 画像の参照実装。既定では無効で、アプリが1行で有効にする。
// 【解説】
// 【解説】 言語に画像の構文を足していないのが要点。:@img(url):@ はただの
// 【解説】 アクションなので、これを知らない実装では img(https://...) という
// 【解説】 読めるテキストに劣化する。新しい記号を1つ消費する価値はないと判断した。
// 【解説】
// 【解説】 それでも「解釈しない」で済ませずパッケージが参照実装を持つのは、
// 【解説】 方言対策。解釈を拒んでも方言は防げず、むしろ各アプリが img(...) や
// 【解説】 image:... を勝手に決めて確実に乱立する。動くものを1つ置くほうが効く。
// 【解説】 加えて :++ が画像に届くことを保証できるのも、こちらが描く場合だけ。
// 【解説】 寄せはブロック単位なので何もしなくても届くが、サイズはビルダーが
// 【解説】 sizeOffset を読まないと効かないため、運任せにしたくない。
// 【解説】
// 【解説】 既定で無効なのは、描画した瞬間に第三者へ通信が飛ぶから。
// 【解説】 ?id=... を仕込めば既読確認にも使えるが、それはトラッキングピクセルと
// 【解説】 技術的に同一で、違いは読み手が知っていて断れるかだけ。メールクライアントが
// 【解説】 軒並みリモート画像を既定でブロックするのと同じ判断をしている。

import 'package:flutter/widgets.dart';

import '../registry/natural_block_registry.dart';

/// The reference rendering for actionable runs that name an image.
///
/// Pass [builder] as `NaturalBlockView.onActionBuild` to draw the
/// conventional `img(<url>)` payload as an actual image:
///
/// ```dart
/// NaturalBlockView(
///   source: source,
///   onActionBuild: NaturalBlockImages.builder,
/// )
/// ```
///
/// ## Why this ships here, and why it is off until you ask
///
/// The language has no image syntax and gains none: `:@img(...):@` is an
/// ordinary actionable run, so an implementation that has never heard of
/// images still shows `img(https://...)` -- readable text a person can act
/// on -- rather than failing to parse.
///
/// Providing the reference interpretation anyway is the point. Declining to
/// interpret would not prevent dialects; it would guarantee them, with every
/// app inventing its own spelling. One implementation that ships is a
/// stronger convention than any amount of non-normative documentation.
///
/// It also keeps the markup's own vocabulary working on images. Block
/// alignment reaches them for free, because that moves the whole block --
/// but `:++` / `:--` only arrives if whatever builds the span bothers to
/// read the style it was handed. Shipping the builder makes that a
/// guarantee rather than something each app might or might not remember.
///
/// It is opt-in because rendering a remote image *is a network request to a
/// third party*, made simply by displaying a document. A URL carrying a
/// per-recipient marker turns that into a read receipt; the same request is
/// a tracking pixel when the reader was not told. That is not a hypothetical
/// -- it is why mail clients block remote images by default -- and it is a
/// disclosure decision belonging to the app, not to a markup renderer. This
/// package cannot tell the two apart, because it never interprets the URL.
abstract final class NaturalBlockImages {
  /// Matches the conventional payload `img(<url>)`, capturing the URL.
  ///
  /// Anchored and non-greedy about nothing in particular: the URL is
  /// whatever sits between the outermost parentheses, so query strings and
  /// nested parentheses in a path survive intact.
  static final RegExp _pattern = RegExp(r'^img\((.+)\)$', dotAll: true);

  /// An [ActionSpanBuilder] that renders `img(<url>)` and declines
  /// everything else by returning `null`.
  ///
  /// Declining is what lets this compose: pass it on its own, or call it
  /// from a builder of your own that handles further payload shapes and
  /// falls back to this one.
  static InlineSpan? builder(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    final url = urlOf(text);
    if (url == null) return null;

    // The size vocabulary arrives as a font size, which is meaningless to a
    // picture -- so it is read as a zoom instead: an unmarked run renders
    // the image at its natural size, and each `:+` step scales it by the
    // same proportion it would have scaled text. That keeps one set of
    // symbols meaning one thing across text and images.
    final scale = _scaleFrom(style);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Image.network(
        url,
        scale: scale,
        // A broken or blocked image falls back to the text that named it,
        // which is the same degradation an implementation without images
        // gives. Nothing a document said should vanish because a request
        // failed.
        errorBuilder: (context, error, stackTrace) =>
            Text(text, style: style),
        // Reserving the line's height keeps text from reflowing once the
        // image arrives; the real size is unknown until then.
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(height: style.fontSize, width: style.fontSize),
      ),
    );
  }

  /// The URL inside a conventional `img(<url>)` payload, or `null` if [text]
  /// is not one -- exposed so an app writing its own builder can reuse the
  /// convention without re-deriving it.
  static String? urlOf(String text) =>
      _pattern.firstMatch(text.trim())?.group(1)?.trim();

  /// Turns the style's font size into an `Image.scale`.
  ///
  /// `scale` divides: a larger number draws the image smaller. So a run
  /// asking for bigger text has to produce a *smaller* scale, hence the
  /// reciprocal.
  static double _scaleFrom(TextStyle style) {
    const reference = 14.0;
    final size = style.fontSize;
    if (size == null || size <= 0) return 1;
    return reference / size;
  }
}
