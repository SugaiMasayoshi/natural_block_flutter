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
    // Already a path, and `toFilePath` would refuse to take it: that accepts
    // an empty scheme or `file` and nothing else, and a Windows drive parses
    // as a one-letter scheme -- so it throws on `C:\Users\a.png`, the most
    // ordinary input here. `kindOf` has already said this is local, so it
    // goes to `File` as written.
    path = source;
  } else {
    try {
      // No `windows:` argument: its default is the platform Dart is running
      // on, which is what this file is for.
      path = uri.toFilePath();
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
