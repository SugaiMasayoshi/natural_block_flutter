import 'dart:io';

import 'package:flutter/widgets.dart';

/// The image at [source], which is a path or a `file:` URI, or null when the
/// URI names no path this platform can open.
///
/// Only ever compiled where `dart:io` exists: the conditional import in
/// `natural_block_images.dart` picks the stub on the web.
Widget? localFileImage(
  String source, {
  required double scale,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  final uri = Uri.tryParse(source);
  if (uri == null) return null;

  final String path;
  if (uri.scheme != 'file') {
    // A plain path, drive letter and all: `uri.path` would have dropped the
    // drive, and `NaturalBlockImages.kindOf` already said this is local.
    path = source;
  } else {
    try {
      path = uri.toFilePath(windows: Platform.isWindows);
    } on UnsupportedError {
      // Thrown for a URI carrying a query, a fragment, or (off Windows) an
      // authority. A document is outside input, so one of those has to
      // decline like any other payload rather than break the line it sits in.
      return null;
    }
  }

  return Image.file(
    File(path),
    scale: scale,
    semanticLabel: source,
    errorBuilder: errorBuilder,
  );
}
