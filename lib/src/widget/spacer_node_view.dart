import 'package:flutter/widgets.dart';

/// A spacer, drawn with [child]. Where the column it stands in has an upper
/// bound on its height, it takes its share of the height left over, by
/// [flex]; where the column has none, or no [SpacerRoom] says, [child] takes
/// only its own height.
class SpacerNodeView extends StatelessWidget {
  final int flex;

  final Widget child;

  const SpacerNodeView({
    super.key,
    required this.flex,
    this.child = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) =>
      Expanded(flex: SpacerRoom.isBoundedOf(context) ? flex : 0, child: child);
}

/// Tells the [SpacerNodeView]s in a column whether its height has an upper
/// bound, which is when they have height to share out.
class SpacerRoom extends InheritedWidget {
  final bool isBounded;

  const SpacerRoom({super.key, required this.isBounded, required super.child});

  static bool isBoundedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpacerRoom>()?.isBounded ??
      false;

  @override
  bool updateShouldNotify(SpacerRoom oldWidget) =>
      isBounded != oldWidget.isBounded;
}
