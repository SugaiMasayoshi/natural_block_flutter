import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockTheme theme;

  final NaturalBlockActions actions;

  const TextNodeView({
    super.key,
    required this.node,
    required this.theme,
    this.actions = NaturalBlockActions.none,
  });

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
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
    var actionIndex = 0;

    final children = widget.node.children;
    if (children.length == 1 && children.single is VerbatimNode) {
      return _VerbatimBlock(
        node: children.single as VerbatimNode,
        theme: widget.theme,
      );
    }

    final spans = widget.node.children.map<InlineSpan>((child) {
      if (child is VerbatimNode) {
        return TextSpan(
          text: child.text,
          style: DefaultTextStyle.of(context).style
              .merge(widget.theme.verbatim),
        );
      }
      final span = child as TextSpanNode;
      final style = widget.theme
          .styleFor(span.color)
          .merge(span.emphasis ? widget.theme.emphasis : null)
          .merge(span.isAction ? widget.theme.action : null)
          .copyWith(
            fontSize: span.sizeOffset != 0
                ? _fontSizeFor(context, span.sizeOffset)
                : null,
          );

      if (span.isAction) {
        final built = widget.actions.buildSpan?.call(
          context,
          span.text,
          style.copyWith(fontSize: style.fontSize ?? _baseFontSize(context)),
          widget.theme,
        );
        if (built != null) return built;
      }

      GestureRecognizer? recognizer;
      final onTap = widget.actions.onTap;
      if (span.isAction && onTap != null) {
        final text = span.text;
        recognizer = _recognizerAt(actionIndex++)..onTap = () => onTap(text);
      }

      return TextSpan(
        text: span.text,
        style: style,
        recognizer: recognizer,
        semanticsLabel: span.isAction && onTap != null ? span.text : null,
      );
    }).toList();

    _trimRecognizers(actionIndex);

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style.merge(widget.theme.base),
        children: spans,
      ),
    );
  }

  double _baseFontSize(BuildContext context) =>
      DefaultTextStyle.of(context).style.fontSize ?? widget.theme.baseFontSize;

  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient = _baseFontSize(context);
    final scaled = ambient + sizeOffset * widget.theme.fontSizeStep;
    return scaled < widget.theme.minFontSize
        ? widget.theme.minFontSize
        : scaled;
  }
}

class _VerbatimBlock extends StatelessWidget {
  final VerbatimNode node;
  final NaturalBlockTheme theme;

  const _VerbatimBlock({required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.verbatim),
      ),
      softWrap: !theme.verbatimScrollsHorizontally,
    );

    return Container(
      padding: theme.verbatimPadding,
      decoration: theme.verbatimDecoration,
      child: theme.verbatimScrollsHorizontally
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
