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

  bool _drawing = false;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _builtFrom = null;
  }

  void _withContext(void Function(BuildContext context) action) {
    assert(
      !_drawing,
      'withContext is for later, such as a tap, not while drawing',
    );
    action(context);
  }

  void _release() {
    final disposes = _disposes;
    _disposes = const [];
    _paragraph = const TextSpan();
    for (final dispose in disposes) {
      try {
        dispose();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'natural_block_flutter',
            context: ErrorDescription('while releasing what a RunHandler drew'),
          ),
        );
      }
    }
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
      _drawing = true;
      final drawn = _runSpans(from, _withContext);
      _drawing = false;
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
  void Function(void Function(BuildContext context) action) withContext,
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
          final custom = (
            text: text,
            style: style,
            theme: theme,
            decoration: run.decoration,
            withContext: withContext,
          );
          for (final handler in from.customs) {
            try {
              claimed = handler(custom);
            } catch (exception, stack) {
              FlutterError.reportError(
                FlutterErrorDetails(
                  exception: exception,
                  stack: stack,
                  library: 'natural_block_flutter',
                  context: ErrorDescription('while a RunHandler drew "$text"'),
                ),
              );
              claimed = null;
            }
            if (claimed != null) break;
          }
        }

        spans[i] = claimed?.span ?? TextSpan(text: text, style: style);
        if (claimed != null) disposes.add(claimed.dispose);
    }
  }

  return (spans: spans, disposes: disposes);
}
