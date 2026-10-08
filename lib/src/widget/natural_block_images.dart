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

  static final RegExp _pattern = RegExp(r'^image\((.+)\)$', dotAll: true);

  static String? urlOf(String text) =>
      _pattern.firstMatch(text.trim())?.group(1)?.trim();

  static final RegExp _driveLetter = RegExp(r'^[A-Za-z]:');

  static ImageSourceKind kindOf(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return ImageSourceKind.relative;

    if (trimmed.startsWith(r'\\')) return ImageSourceKind.file;
    if (_driveLetter.hasMatch(trimmed)) return ImageSourceKind.file;
    if (trimmed.startsWith('/')) return ImageSourceKind.file;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return uri.scheme == 'file'
          ? ImageSourceKind.file
          : ImageSourceKind.network;
    }
    return ImageSourceKind.relative;
  }
}
