import 'package:flutter/widgets.dart';

import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';
import 'natural_block_theme.dart';

enum ImageSourceKind { network, file, relative }

abstract final class NaturalBlockImages {
  static final RegExp _pattern = RegExp(r'^image\((.+)\)$', dotAll: true);

  /// Draws `image(<url>)` payloads that name a network image, and declines
  /// everything else.
  static InlineSpan? builder(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) => _span(text, style, theme, localFiles: false);

  /// The same, and local files as well.
  ///
  /// A document that names a local file draws one from the reader's own
  /// machine, which is a different decision from fetching a remote one: a
  /// shared note rendering the reader's own picture is the point in one app
  /// and a way to put someone else's file on the reader's screen in another.
  /// Only the app knows which it is, so this is a second entry point rather
  /// than a change to [builder].
  ///
  /// Where `dart:io` does not exist -- the web -- a local file declines as
  /// before, so a document degrades the same way it does everywhere else.
  static InlineSpan? withLocalFiles(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) => _span(text, style, theme, localFiles: true);

  static InlineSpan? _span(
    String text,
    TextStyle style,
    NaturalBlockTheme theme, {
    required bool localFiles,
  }) {
    final url = urlOf(text);
    if (url == null) return null;

    final kind = kindOf(url);
    if (kind == ImageSourceKind.relative) return null;
    if (kind == ImageSourceKind.file && !localFiles) return null;

    final runSize = style.fontSize ?? theme.baseFontSize;
    // `Image.scale` says how many of the image's own pixels go in a logical
    // one, so it divides: pass less than 1 and the image is drawn larger.
    final drawnWithTheRun = theme.baseFontSize / runSize;
    Widget asText(BuildContext context, Object error, StackTrace? stack) =>
        Text(text, style: style);

    final image = kind == ImageSourceKind.network
        ? Image.network(
            url,
            scale: drawnWithTheRun,
            semanticLabel: url,
            errorBuilder: asText,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : SizedBox(height: runSize, width: runSize),
          )
        : localFileImage(url, scale: drawnWithTheRun, errorBuilder: asText);
    if (image == null) return null;

    return WidgetSpan(alignment: PlaceholderAlignment.middle, child: image);
  }

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
