import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

/// Renders a [TextNode]'s [TextSpanNode] children as a single rich text
/// run, mapping each span's [SemanticColor], emphasis flag, and
/// `sizeOffset` onto [TextStyle] via [theme].
///
/// Built with [Text.rich] rather than a bare [RichText] so the result takes
/// part in text selection: a consumer who wraps a `NaturalBlockView` in a
/// `SelectionArea` gets selectable, copyable text, including drags that
/// cross cell and row boundaries. A directly-constructed [RichText] does
/// not register with the selection machinery and would be unselectable.
///
/// A [StatefulWidget] rather than stateless: a span with
/// `TextSpanNode.isAction == true` needs a [TapGestureRecognizer] attached
/// to its [TextSpan], and recognizers are disposable objects that must be
/// torn down explicitly -- something a stateless build method has nowhere
/// to do. The state rebuilds its recognizer list on every `build` (disposing
/// the previous batch first) and disposes whatever's left in `dispose()`.
class TextNodeView extends StatefulWidget {
  /// The node whose [TextNode.children] spans are rendered.
  final TextNode node;

  /// Styling used to turn each span's semantic color, emphasis, and
  /// `sizeOffset` into a concrete [TextStyle].
  final NaturalBlockTheme theme;

  /// Called with a span's own `text` when a span with
  /// `TextSpanNode.isAction == true` is tapped. When `null`, actionable
  /// spans still render with [NaturalBlockTheme.action] but get no tap
  /// recognizer at all -- nothing is created, so there is nothing to
  /// dispose.
  final OnActionTap? onActionTap;

  const TextNodeView({
    super.key,
    required this.node,
    required this.theme,
    this.onActionTap,
  });

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  final List<TapGestureRecognizer> _recognizers = [];

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

  @override
  Widget build(BuildContext context) {
    // Rebuilt (and any previous recognizers replaced) on every build, not
    // just in didUpdateWidget: a build can also be triggered by something
    // that doesn't change the widget instance (e.g. an ambient
    // InheritedWidget), and a stale recognizer bound to a stale
    // `widget.onActionTap` would silently call the wrong callback.
    _disposeRecognizers();

    final spans = widget.node.children.map((span) {
      final style = widget.theme
          .styleFor(span.color)
          .merge(span.emphasis ? widget.theme.emphasis : null)
          .merge(span.isAction ? widget.theme.action : null)
          .copyWith(
            fontSize: span.sizeOffset != 0
                ? _fontSizeFor(context, span.sizeOffset)
                : null,
          );

      GestureRecognizer? recognizer;
      if (span.isAction && widget.onActionTap != null) {
        final onActionTap = widget.onActionTap!;
        final text = span.text;
        final tap = TapGestureRecognizer()
          ..onTap = () => onActionTap(text);
        _recognizers.add(tap);
        recognizer = tap;
      }

      return TextSpan(text: span.text, style: style, recognizer: recognizer);
    }).toList();

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style.merge(widget.theme.base),
        children: spans,
      ),
    );
  }

  /// Computes the font size for a span with a non-zero [sizeOffset],
  /// scaling from the ambient font size (or [NaturalBlockTheme.baseFontSize]
  /// if there is none) by [NaturalBlockTheme.fontSizeStep] points per step.
  ///
  /// The result is clamped to [NaturalBlockTheme.minFontSize] so a large
  /// negative [sizeOffset] (the parser supports e.g. `:-----`, an offset of
  /// -5) cannot drive the font size to zero or below, which Flutter's
  /// [TextStyle] asserts against.
  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient =
        DefaultTextStyle.of(context).style.fontSize ??
        widget.theme.baseFontSize;
    final scaled = ambient + sizeOffset * widget.theme.fontSizeStep;
    return scaled < widget.theme.minFontSize
        ? widget.theme.minFontSize
        : scaled;
  }
}
