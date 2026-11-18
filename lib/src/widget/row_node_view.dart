import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A row's cells, each given an equal share of the width.
///
/// The cells line up on the baseline of their first lines, so text of
/// different sizes sits on one line, as it would inside a paragraph. Cells
/// whose first lines are the same size start at the same height. The row is
/// as tall as its tallest cell.
///
/// A cell may then take up to the row's height. One that grows into it, as a
/// cell with a spacer does, runs from the top of the row instead.
///
/// Where the width has no upper bound, each cell takes the width of its
/// content.
class RowNodeView extends MultiChildRenderObjectWidget {
  const RowNodeView({super.key, required List<Widget> cells})
    : super(children: cells);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRow(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRow).textDirection = Directionality.of(context);
  }
}

class _CellParentData extends ContainerBoxParentData<RenderBox> {
  bool grew = false;
}

class _RenderRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellParentData> {
  _RenderRow(this._textDirection);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellParentData) {
      child.parentData = _CellParentData();
    }
  }

  @override
  void performLayout() {
    final cells = getChildrenAsList();

    final cellWidth = constraints.hasBoundedWidth && cells.isNotEmpty
        ? constraints.maxWidth / cells.length
        : null;

    BoxConstraints upTo(double height) => BoxConstraints(
      minWidth: cellWidth ?? 0,
      maxWidth: cellWidth ?? double.infinity,
      maxHeight: height,
    );

    for (final cell in cells) {
      cell.layout(upTo(double.infinity), parentUsesSize: true);
    }

    final ascent = cells.map(_baselineOf).nonNulls.fold(0.0, max);
    final measured = [
      for (final cell in cells)
        (
          cell: cell,
          height: cell.size.height,
          top: switch (_baselineOf(cell)) {
            final baseline? => ascent - baseline,
            null => 0.0,
          },
        ),
    ];

    final rowHeight = constraints.constrainHeight(
      measured.map((cell) => cell.top + cell.height).fold(0.0, max),
    );

    var x = 0.0;
    for (final (:cell, :height, :top)
        in _textDirection == TextDirection.rtl ? measured.reversed : measured) {
      if (height < rowHeight) {
        cell.layout(upTo(rowHeight), parentUsesSize: true);
      }
      final parentData = cell.parentData! as _CellParentData
        ..grew = cell.size.height > height;
      parentData.offset = Offset(x, parentData.grew ? 0 : top);
      x += cell.size.width;
    }

    size = constraints.constrain(Size(x, rowHeight));
  }

  double? _baselineOf(RenderBox cell) =>
      cell.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    for (final cell in getChildrenAsList()) {
      final parentData = cell.parentData! as _CellParentData;
      if (parentData.grew) continue;
      final distance = cell.getDistanceToActualBaseline(baseline);
      if (distance != null) return distance + parentData.offset.dy;
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
