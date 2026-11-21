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

  bool _endsWithLineBreak = false;

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
      _endsWithLineBreak = drawn.endsWithLineBreak;
    }

    final paragraph = Text.rich(_paragraph);
    if (!_endsWithLineBreak) return paragraph;
    // A paragraph that ends in a line break gives its empty last line the
    // height of the line before, so that line is drawn apart, at body size.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        paragraph,
        Text('', style: rootStyle),
      ],
    );
  }
}

// Everything the spans are built from, and so everything they are compared by.
typedef _SpanInputs = ({
  TextNode line,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
  List<RunHandler> customs,
});

({List<InlineSpan> spans, List<VoidCallback> disposes, bool endsWithLineBreak})
_runSpans(
  _SpanInputs from,
  void Function(void Function(BuildContext context) action) withContext,
) {
  final theme = from.theme;
  final runs = from.line.children;

  final spans = List<InlineSpan>.filled(runs.length, const TextSpan());
  final disposes = <VoidCallback>[];
  final endsWithLineBreak = switch (runs.last) {
    TextSpanNode(:final text) => text.endsWith('\n'),
    RawSpanNode() => false,
  };

  final baseSize = from.rootStyle.fontSize ?? kDefaultFontSize;
  for (var i = 0; i < runs.length; i++) {
    final run = runs[i];
    final style = theme.styleFor(run.decoration, baseSize: baseSize);
    switch (run) {
      case RawSpanNode():
        spans[i] = TextSpan(
          text: run.text,
          style: style
              .merge(theme.raw)
              .copyWith(
                fontSize: style.fontSize,
                backgroundColor: theme.rawDecoration?.color,
              ),
        );

      case TextSpanNode():
        final isLast = i == runs.length - 1;
        final text = isLast && endsWithLineBreak
            ? run.text.substring(0, run.text.length - 1)
            : run.text;

        RunRendering? claimed;
        if (run.decoration.isCustom) {
          final custom = CustomRun(
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

  return (
    spans: spans,
    disposes: disposes,
    endsWithLineBreak: endsWithLineBreak,
  );
}
