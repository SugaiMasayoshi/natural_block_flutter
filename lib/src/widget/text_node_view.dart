import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../custom/run_handler.dart';
import '../render/natural_block_builders.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

// Spans are kept across builds: replacing a recognizer mid-gesture drops the tap.
class _TextNodeViewState extends State<TextNodeView> {
  List<VoidCallback> _disposes = const [];

  TextSpan _paragraph = const TextSpan();

  _SpanInputs? _builtFrom;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _release() {
    for (final dispose in _disposes) {
      dispose();
    }
    _disposes = const [];
    _paragraph = const TextSpan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.scope.theme;

    // One expression for the root span and the size `:+` counts from, or they drift.
    final rootStyle = DefaultTextStyle.of(context).style.merge(theme.base);

    final from = (
      line: widget.node,
      theme: theme,
      rootStyle: rootStyle,
      customs: widget.scope.customs,
    );

    if (from != _builtFrom) {
      _builtFrom = from;
      _release();
      final drawn = _runSpans(from);
      _disposes = drawn.disposes;
      _paragraph = TextSpan(style: rootStyle, children: drawn.spans);
    }

    return Text.rich(_paragraph);
  }
}

// Everything the spans are built from, and so everything they are compared by.
typedef _SpanInputs = ({
  TextNode line,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
  List<RunHandler> customs,
});

({List<InlineSpan> spans, List<VoidCallback> disposes}) _runSpans(
  _SpanInputs from,
) {
  final theme = from.theme;
  final runs = from.line.children;

  final spans = List<InlineSpan>.filled(runs.length, const TextSpan());
  final disposes = <VoidCallback>[];

  for (var i = 0; i < runs.length; i++) {
    final run = runs[i];
    switch (run) {
      case RawSpanNode():
        spans[i] = TextSpan(
          text: run.text,
          style: from.rootStyle.merge(theme.raw),
        );

      case TextSpanNode():
        final text = run.text;
        final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
        final style = theme.styleFor(run.decoration, baseSize: baseSize);

        RunRendering? claimed;
        if (run.decoration.isCustom) {
          // `styleFor` leaves the size unstated when the source asked for no step.
          final offered = style.copyWith(fontSize: style.fontSize ?? baseSize);
          for (final handler in from.customs) {
            claimed = handler(text, offered, theme);
            if (claimed != null) break;
          }
        }

        spans[i] = claimed?.span ?? TextSpan(text: text, style: style);
        if (claimed != null) disposes.add(claimed.dispose);
    }
  }

  return (spans: spans, disposes: disposes);
}
