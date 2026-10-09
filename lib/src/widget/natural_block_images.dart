import 'package:flutter/widgets.dart';

import '../render/run_handler.dart';
import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';
import 'natural_block_theme.dart';

enum ImageSourceKind { network, file, relative }

/// The reference rendering for the conventional `image(<source>)` payload.
///
/// Two handlers rather than one with a switch, because fetching a remote
/// image and reading the reader's own file are different decisions. A remote
/// one tells a third party the document was opened; a local one puts a file
/// from the reader's machine on screen under someone else's text. An app
/// includes whichever it means, and only that one -- local without network is
/// a position a document viewer may well want to take.
abstract final class NaturalBlockImages {
  /// Draws an `image(...)` payload that names a network source.
  static RunRendering? network(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
    VoidCallback? onTap,
  ) {
    final url = urlOf(text);
    if (url == null || kindOf(url) != ImageSourceKind.network) return null;

    return _inTheLine(
      Image.network(
        url,
        scale: _drawnWithTheRun(style, theme),
        semanticLabel: url,
        errorBuilder: _asText(text, style),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox.square(dimension: _runSize(style, theme)),
      ),
    );
  }

  /// Draws an `image(...)` payload that names a local file, by path or by a
  /// `file:` URI.
  ///
  /// Where `dart:io` does not exist -- the web -- this declines, so a
  /// document degrades there the way it does for an app that never included
  /// it at all.
  static RunRendering? local(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
    VoidCallback? onTap,
  ) {
    final url = urlOf(text);
    if (url == null || kindOf(url) != ImageSourceKind.file) return null;

    final image = localFileImage(
      url,
      scale: _drawnWithTheRun(style, theme),
      errorBuilder: _asText(text, style),
    );
    return image == null ? null : _inTheLine(image);
  }

  /// An image drawn where the run was, centred on the text beside it, with
  /// nothing to release: everything inside a `WidgetSpan` gets the ordinary
  /// widget lifecycle, so Flutter disposes it.
  static RunRendering _inTheLine(Widget image) => (
    span: WidgetSpan(alignment: PlaceholderAlignment.middle, child: image),
    dispose: () {},
  );

  static double _runSize(TextStyle style, NaturalBlockTheme theme) =>
      style.fontSize ?? theme.baseFontSize;

  /// `Image.scale` says how many of the image's own pixels go in a logical
  /// one, so it divides: pass less than 1 and the image is drawn larger.
  static double _drawnWithTheRun(TextStyle style, NaturalBlockTheme theme) =>
      theme.baseFontSize / _runSize(style, theme);

  /// An image that cannot be drawn falls back to its own payload, the way an
  /// unrecognised one does.
  static ImageErrorWidgetBuilder _asText(String text, TextStyle style) =>
      (context, error, stackTrace) => Text(text, style: style);

  static const String _opening = 'image(';

  /// The source an `image(...)` payload names, or null when [text] names
  /// none -- an empty `image()` included.
  static String? urlOf(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith(_opening) || !trimmed.endsWith(')')) return null;

    final source = trimmed
        .substring(_opening.length, trimmed.length - 1)
        .trim();
    return source.isEmpty ? null : source;
  }

  /// Where a payload points, read off one `Uri`.
  static ImageSourceKind kindOf(String source) {
    final uri = Uri.tryParse(source.trim());
    if (uri == null) return ImageSourceKind.relative;

    // `Uri` reads `C:/Users/a.png` as scheme `c`, and no registered scheme
    // is one letter, so a one-letter scheme is a drive.
    if (uri.scheme.length == 1 || uri.scheme == 'file') {
      return ImageSourceKind.file;
    }
    if (uri.hasScheme) return ImageSourceKind.network;

    // Rooted with no scheme is this machine's, by absolute path or by UNC.
    // Unrooted needs a base that only the app has.
    return uri.hasAbsolutePath
        ? ImageSourceKind.file
        : ImageSourceKind.relative;
  }
}
