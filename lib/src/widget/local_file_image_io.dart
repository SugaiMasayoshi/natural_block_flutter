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
}) => Image.file(
  File(_pathOf(source)),
  scale: scale,
  semanticLabel: source,
  errorBuilder: errorBuilder,
);

/// A `file:` URI as the path it names, and anything else unchanged.
String _pathOf(String source) {
  if (!source.startsWith('file:')) return source;
  final uri = Uri.tryParse(source);
  if (uri == null) return source;
  return uri.toFilePath(windows: Platform.isWindows);
}
