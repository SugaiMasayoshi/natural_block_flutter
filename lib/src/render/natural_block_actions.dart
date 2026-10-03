import 'package:flutter/widgets.dart';

import '../widget/natural_block_theme.dart';

typedef OnActionTap = void Function(String text);

typedef ActionSpanBuilder = InlineSpan? Function(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
);

class NaturalBlockActions {
  final OnActionTap? onTap;

  final ActionSpanBuilder? buildSpan;

  const NaturalBlockActions({this.onTap, this.buildSpan});

  static const NaturalBlockActions none = NaturalBlockActions();
}
