import 'package:flutter/widgets.dart';

// The web has no `dart:io`, so a local path declines.
Widget? localFileImage(
  String source, {
  required String label,
  required ImageErrorWidgetBuilder errorBuilder,
}) => null;
