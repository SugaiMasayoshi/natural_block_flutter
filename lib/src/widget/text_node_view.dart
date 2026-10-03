import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_actions.dart';
import '../render/natural_block_builders.dart';
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

  /// This line's runs as spans, built once and kept until something they are
  /// made of changes.
  ///
  /// Not built in `build`, because `build` runs for reasons the spans owe
  /// nothing to -- an ancestor rebuilding, every frame of an animating
  /// parent. Rebuilding them there replaced the recognizers below on each of
  /// those, and a recognizer that has taken a pointer down owns an entry in
  /// the gesture arena: replace it mid-gesture and the tap vanishes silently.
  /// Keeping the spans is what keeps the recognizers.
  late List<InlineSpan> _spans;

  /// The recognizers the spans above carry, owned so they can be disposed.
  ///
  /// A flat list, because they are only ever created and released together
  /// with the spans -- there is no pool to keep in step with anything.
  final List<TapGestureRecognizer> _recognizers = [];

  /// Rebuilds the spans when an inherited widget they read changes.
  ///
  /// `DefaultTextStyle` is one: it decides what every run starts from, and it
  /// can change without this widget's own fields changing at all.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildSpans();
  }

  /// Rebuilds the spans when what they are made of changes.
  ///
  /// `onTap`'s identity is deliberately not compared -- only whether it is
  /// null, which is what decides if a run carries a recognizer at all. The
  /// callback itself is read at tap time, so a caller writing a fresh closure
  /// on every build does not cost a rebuild here.
  @override
  void didUpdateWidget(TextNodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.scope;
    if (widget.node != oldWidget.node ||
        _theme != old.theme ||
        _actions.buildSpan != old.actions.buildSpan ||
        (_actions.onTap == null) != (old.actions.onTap == null)) {
      _buildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Builds the spans, releasing the recognizers the previous ones carried.
  void _buildSpans() {
    _disposeRecognizers();
    _spans = [
      for (final child in widget.node.children)
        switch (child) {
          RawSpanNode() => _rawSpan(context, child),
          TextSpanNode() => _textSpan(context, child),
        },
    ];
  }

  /// A recognizer for a run reading [text], owned by this state.
  TapGestureRecognizer _recognizerFor(String text) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => _actions.onTap?.call(text);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(style: _rootStyle(context), children: _spans));

  InlineSpan _rawSpan(BuildContext context, RawSpanNode node) => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(_theme.raw),
  );

  /// The span for one styled run, or whatever [ActionSpanBuilder] returned
  /// for it.
  InlineSpan _textSpan(BuildContext context, TextSpanNode span) {
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

    final recognizer = span.decoration.isAction && _actions.onTap != null
        ? _recognizerFor(span.text)
        : null;

    return TextSpan(
      text: span.text,
      style: style,
      recognizer: recognizer,
      semanticsLabel: recognizer != null ? span.text : null,
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
