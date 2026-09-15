import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  NaturalBlockTheme get _theme => widget.scope.theme;

  NaturalBlockActions get _actions => widget.scope.actions;

  /// What every run of this line starts from: the ambient style with the
  /// theme's `base` merged over it.
  ///
  /// One expression, because two of them is a bug rather than a repetition.
  /// The root span is built from this and so is the baseline a `:+` counts
  /// from; when they drifted apart, a theme whose `base` named a size made
  /// `:+` render *smaller* than the text beside it.
  TextStyle _rootStyle(BuildContext context) =>
      DefaultTextStyle.of(context).style.merge(_theme.base);

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  TapGestureRecognizer _recognizerAt(int index) {
    while (_recognizers.length <= index) {
      _recognizers.add(TapGestureRecognizer());
    }
    return _recognizers[index];
  }

  void _trimRecognizers(int keep) {
    while (_recognizers.length > keep) {
      _recognizers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers are numbered across the whole line and reclaimed by count,
    // so the tally is issued and collected in the same place. A span that
    // needs one asks for the next number; `_trimRecognizers` disposes the
    // rest.
    var actionIndex = 0;

    final spans = widget.node.children.map<InlineSpan>((child) {
      if (child is RawSpanNode) return _rawSpan(context, child);
      return _textSpan(context, child as TextSpanNode, () => actionIndex++);
    }).toList();

    _trimRecognizers(actionIndex);

    return Text.rich(TextSpan(style: _rootStyle(context), children: spans));
  }

  InlineSpan _rawSpan(BuildContext context, RawSpanNode node) => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(_theme.raw),
  );

  /// The span for one styled run, or whatever [ActionSpanBuilder] returned
  /// for it. [nextAction] hands out the next recognizer number, and is only
  /// called when a recognizer is actually taken.
  InlineSpan _textSpan(
    BuildContext context,
    TextSpanNode span,
    int Function() nextAction,
  ) {
    final style = _theme
        .styleFor(span.decoration.tone)
        .merge(span.decoration.emphasis ? _theme.emphasis : null)
        .merge(span.decoration.isAction ? _theme.action : null)
        .copyWith(
          fontSize: span.decoration.sizeOffset != 0
              ? _fontSizeFor(context, span.decoration.sizeOffset)
              : null,
        );

    if (span.decoration.isAction) {
      final built = _actions.buildSpan?.call(
        context,
        span.text,
        style.copyWith(fontSize: style.fontSize ?? _baseFontSize(context)),
        _theme,
      );
      if (built != null) return built;
    }

    GestureRecognizer? recognizer;
    final onTap = _actions.onTap;
    if (span.decoration.isAction && onTap != null) {
      final text = span.text;
      recognizer = _recognizerAt(nextAction())..onTap = () => onTap(text);
    }

    return TextSpan(
      text: span.text,
      style: style,
      recognizer: recognizer,
      semanticsLabel: span.decoration.isAction && onTap != null
          ? span.text
          : null,
    );
  }

  /// The size a run of this line draws at before any `:+` or `:-`.
  double _baseFontSize(BuildContext context) =>
      _rootStyle(context).fontSize ?? _theme.baseFontSize;

  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient = _baseFontSize(context);
    final scaled = ambient + sizeOffset * _theme.fontSizeStep;
    return scaled < _theme.minFontSize ? _theme.minFontSize : scaled;
  }
}
