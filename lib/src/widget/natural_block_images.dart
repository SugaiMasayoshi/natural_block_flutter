import 'package:flutter/widgets.dart';

import 'natural_block_theme.dart';

enum ImageSourceKind { network, file, relative }

abstract final class NaturalBlockImages {
  static final RegExp _pattern = RegExp(r'^image\((.+)\)$', dotAll: true);

  static InlineSpan? builder(
    BuildContext context,
    String text,
    TextStyle style,
    NaturalBlockTheme theme,
  ) {
    final url = urlOf(text);
    if (url == null || kindOf(url) != ImageSourceKind.network) return null;

    final size = style.fontSize ?? theme.baseFontSize;
    final scale = theme.baseFontSize / size;

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Image.network(
        url,
        scale: scale,
        semanticLabel: url,
        errorBuilder: (context, error, stackTrace) => Text(text, style: style),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : SizedBox(height: size, width: size),
      ),
    );
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
