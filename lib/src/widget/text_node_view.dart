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

  TextSpan _line = const TextSpan();

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
    if (mounted) action(context);
  }

  void _release() {
    final disposes = _disposes;
    _disposes = const [];
    _line = const TextSpan();
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
      _line = TextSpan(style: rootStyle, children: drawn.spans);
    }

    return Text.rich(_line, style: rootStyle);
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
  final disposes = <VoidCallback>[];
  final baseSize = from.rootStyle.fontSize ?? kDefaultFontSize;
  InlineSpan spanOf(InlineNode run) {
    final style = theme.styleFor(run.decoration, baseSize: baseSize);
    switch (run) {
      case RawSpanNode():
        return TextSpan(
          text: run.text,
          style: style
              .merge(theme.raw)
              .copyWith(
                fontSize: style.fontSize,
                backgroundColor: theme.rawDecoration?.color,
              ),
        );

      case TextSpanNode():
        RunRendering? claimed;
        if (run.decoration.isCustom) {
          final custom = CustomRun(
            text: run.text,
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
                  context: ErrorDescription(
                    'while a RunHandler drew "${run.text}"',
                  ),
                ),
              );
              claimed = null;
            }
            if (claimed != null) break;
          }
        }

        if (claimed != null) disposes.add(claimed.dispose);
        return claimed?.span ?? TextSpan(text: run.text, style: style);
    }
  }

  return (
    spans: [for (final run in from.line.children) spanOf(run)],
    disposes: disposes,
  );
}
