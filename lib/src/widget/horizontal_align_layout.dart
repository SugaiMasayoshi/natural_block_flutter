import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

/// How a `HorizontalAlign` becomes Flutter layout.
///
/// Both views used to hold their own copy of this mapping, written once as a
/// `switch` statement and once as a switch expression, which made the
/// duplication easy to miss.
///
/// An unstated alignment draws at the start, which is a *drawing* decision:
/// the tree keeps it apart from `start` so a theme can tell them apart, and
/// this is where the two finally meet.
extension HorizontalAlignLayout on HorizontalAlign {
  /// Whether this needs no `Align` wrapper at all.
  bool get isStart =>
      this == HorizontalAlign.unstated || this == HorizontalAlign.start;

  CrossAxisAlignment get crossAxis => switch (this) {
    HorizontalAlign.unstated ||
    HorizontalAlign.start => CrossAxisAlignment.start,
    HorizontalAlign.center => CrossAxisAlignment.center,
    HorizontalAlign.end => CrossAxisAlignment.end,
  };

  AlignmentGeometry get alignment => switch (this) {
    HorizontalAlign.unstated ||
    HorizontalAlign.start => AlignmentDirectional.centerStart,
    HorizontalAlign.center => Alignment.center,
    HorizontalAlign.end => AlignmentDirectional.centerEnd,
  };
}
