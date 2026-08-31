import 'package:flutter/widgets.dart';

/// Renders pre-built child widgets in a vertically stacked [Column].
class ColumnNodeView extends StatelessWidget {
  /// The already-built widgets to stack vertically, in order. Building
  /// these from the source `ColumnNode`'s children (typically via
  /// `NaturalBlockRegistry.buildAll`) is the caller's responsibility --
  /// this widget only lays them out.
  final List<Widget> children;

  const ColumnNodeView({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}
