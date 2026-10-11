import 'dart:io';

import 'package:flutter/widgets.dart';

Widget? localFileImage(
  String source, {
  required double scale,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  final uri = Uri.tryParse(source);
  if (uri == null) return null;

  final String path;
  if (uri.scheme != 'file') {
    // Not a URI, and `toFilePath` throws on a drive letter (read as a scheme).
    path = source;
  } else {
    try {
      path = uri.toFilePath();
    } on UnsupportedError {
      // A query, fragment or authority: decline rather than break the line.
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
