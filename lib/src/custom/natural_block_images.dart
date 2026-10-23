import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';
import 'run_handler.dart';

enum ImageSourceKind { network, file, relative }

/// The reference rendering for the `image(<source>)` payload: `network` and
/// `local` are handlers, and an app includes the ones it means. An image that
/// cannot be drawn falls back to its payload as text.
abstract final class NaturalBlockImages {
  /// Draws `image(<url>)` by fetching it.
  static RunRendering? network(
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
    SpanDecoration decoration,
  ) {
    final source = sourceOf(text);
    if (source == null || kindOf(source) != ImageSourceKind.network) {
      return null;
    }

    final runSize = style.fontSize!;
    return widgetRun(
      Image.network(
        source,
        scale: scaleOf(decoration, theme),
        semanticLabel: source,
        errorBuilder: (_, _, _) => Text(text, style: style),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : SizedBox.square(dimension: runSize),
      ),
    );
  }

  /// Draws `image(<path>)` or `image(file:...)` by reading the file. Declines
  /// where there is no `dart:io`, the web.
  static RunRendering? local(
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
    SpanDecoration decoration,
  ) {
    final source = sourceOf(text);
    if (source == null || kindOf(source) != ImageSourceKind.file) return null;

    final image = localFileImage(
      source,
      scale: scaleOf(decoration, theme),
      errorBuilder: (_, _, _) => Text(text, style: style),
    );
    return image == null ? null : widgetRun(image);
  }

  /// `Image.scale` for a run: 1 with no step, so an image keeps its own size,
  /// and each `:+` or `:-` moves it by `fontSizeStep` against `baseFontSize`.
  /// It divides, so less than 1 draws the image larger.
  static double scaleOf(SpanDecoration decoration, NaturalBlockTheme theme) =>
      theme.baseFontSize /
      theme.styleFor(decoration, baseSize: theme.baseFontSize).fontSize!;

  static const String _prefix = 'image(';

  /// What an `image(...)` payload names, or null when it is not one exactly:
  /// an empty `image()` and any surrounding whitespace are declined, not
  /// trimmed away.
  static String? sourceOf(String text) {
    if (!text.startsWith(_prefix) || !text.endsWith(')')) return null;

    final source = text.substring(_prefix.length, text.length - 1);
    return source.isEmpty || source != source.trim() ? null : source;
  }

  /// Where a source points: a network URL, a local file, or a path relative to
  /// something only the app knows.
  static ImageSourceKind kindOf(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) return ImageSourceKind.relative;

    // `Uri` reads `C:/Users/a.png` as scheme `c`, and no registered scheme
    // is one letter, so a one-letter scheme is a drive.
    if (uri.scheme.length == 1 || uri.scheme == 'file') {
      return ImageSourceKind.file;
    }
    if (uri.hasScheme) return ImageSourceKind.network;

    // Rooted with no scheme is this machine's, UNC included. Unrooted
    // needs a base only the app has.
    return uri.hasAbsolutePath
        ? ImageSourceKind.file
        : ImageSourceKind.relative;
  }
}
