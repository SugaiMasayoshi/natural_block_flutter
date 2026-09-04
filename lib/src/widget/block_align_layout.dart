import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

/// How a `BlockAlign` becomes Flutter layout.
///
/// On the nullable type because "the source stated nothing" is a value the
/// tree carries everywhere, and every drawing decision has to answer it the
/// same way. Both views used to hold their own copy of this mapping, written
/// once as a `switch` statement and once as a switch expression, which made
/// the duplication easy to miss.
extension BlockAlignLayout on BlockAlign? {
  /// What to draw with. An unstated alignment draws at the start.
  BlockAlign get orStart => this ?? BlockAlign.start;

  /// Whether this needs no `Align` wrapper at all.
  bool get isStart => orStart == BlockAlign.start;

  CrossAxisAlignment get crossAxis => switch (orStart) {
    BlockAlign.start => CrossAxisAlignment.start,
    BlockAlign.center => CrossAxisAlignment.center,
    BlockAlign.end => CrossAxisAlignment.end,
  };

  AlignmentGeometry get alignment => switch (orStart) {
    BlockAlign.start => AlignmentDirectional.centerStart,
    BlockAlign.center => Alignment.center,
    BlockAlign.end => AlignmentDirectional.centerEnd,
  };
}
