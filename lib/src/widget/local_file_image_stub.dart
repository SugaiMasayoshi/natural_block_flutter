import 'package:flutter/widgets.dart';

/// No local file to draw where `dart:io` does not exist.
///
/// The web build compiles this file instead of `local_file_image_io.dart`,
/// so nothing here reaches for a file system that is not there. A payload
/// naming a local file falls back to its own text, exactly as it does for
/// an app that never asked for local files at all.
Widget? localFileImage(
  String source, {
  required double scale,
  required ImageErrorWidgetBuilder errorBuilder,
}) => null;
