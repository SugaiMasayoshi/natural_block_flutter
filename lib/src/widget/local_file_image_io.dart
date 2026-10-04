import 'dart:io';

import 'package:flutter/widgets.dart';

/// The image at [source], which is a path or a `file:` URI.
///
/// Only ever compiled where `dart:io` exists: the conditional import in
/// `natural_block_images.dart` picks the stub on the web.
Widget? localFileImage(
  String source, {
  required double scale,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  final path = _pathOf(source);
  if (path == null) return null;
  return Image.file(
    File(path),
    scale: scale,
    semanticLabel: source,
    errorBuilder: errorBuilder,
  );
}

/// A `file:` URI as the path it names, or null when it names none.
///
/// `toFilePath` throws for a URI carrying a query, a fragment, or (off
/// Windows) an authority. A document is outside input, so one of those has
/// to decline like any other payload rather than break the line it sits on.
String? _pathOf(String source) {
  if (!source.startsWith('file:')) return source;
  final uri = Uri.tryParse(source);
  if (uri == null) return null;
  try {
    return uri.toFilePath(windows: Platform.isWindows);
  } on UnsupportedError {
    return null;
  }
}
