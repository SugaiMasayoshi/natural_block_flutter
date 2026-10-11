import 'package:flutter/widgets.dart';

import '../render/run_handler.dart';
import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';
import 'natural_block_theme.dart';

enum ImageSourceKind { network, file, relative }

/// The reference rendering for the conventional `image(<source>)` payload.
///
/// Two handlers, because fetching a remote image and reading the reader's
/// own file are different decisions: one tells a third party the document
/// was opened, the other puts a file from the reader's machine on screen
/// under someone else's text. An app includes whichever it means.
///
/// Either way, an image that cannot be drawn falls back to its payload as
/// text.
abstract final class NaturalBlockImages {
  /// Draws `image(<url>)` by fetching it.
  static RunRendering? network(
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) {
    final source = sourceOf(text);
    if (source == null || kindOf(source) != ImageSourceKind.network) {
      return null;
    }

    final runSize = style.fontSize ?? theme.baseFontSize;
    return widgetRun(
      Image.network(
        source,
        // `Image.scale` says how many of the image's own pixels go in a
        // logical one, so it divides: less than 1 draws the image larger.
        scale: theme.baseFontSize / runSize,
        semanticLabel: source,
        errorBuilder: (_, _, _) => Text(text, style: style),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : SizedBox.square(dimension: runSize),
      ),
    );
  }

  /// Draws `image(<path>)` or `image(file:...)` by reading the file.
  ///
  /// Declines everything where `dart:io` does not exist -- the web -- so a
  /// document degrades there as it does for an app that never included it.
  static RunRendering? local(
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) {
    final source = sourceOf(text);
    if (source == null || kindOf(source) != ImageSourceKind.file) return null;

    final image = localFileImage(
      source,
      scale: theme.baseFontSize / (style.fontSize ?? theme.baseFontSize),
      errorBuilder: (_, _, _) => Text(text, style: style),
    );
    return image == null ? null : widgetRun(image);
  }

  static const String _prefix = 'image(';

  /// What an `image(...)` payload names, or null when it names nothing --
  /// an empty `image()` included.
  static String? sourceOf(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith(_prefix) || !trimmed.endsWith(')')) return null;

    final source = trimmed.substring(_prefix.length, trimmed.length - 1).trim();
    return source.isEmpty ? null : source;
  }

  /// Where a source points, read off one `Uri`.
  static ImageSourceKind kindOf(String source) {
    final uri = Uri.tryParse(source.trim());
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
