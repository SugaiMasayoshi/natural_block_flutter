import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'local_file_image_stub.dart'
    if (dart.library.io) 'local_file_image_io.dart';
import 'run_handler.dart';

enum ImageSourceKind { network, file, relative }

/// The reference rendering for the `image(<source>)` payload: `network` and
/// `local` are handlers, and an app includes the ones it means. An image that
/// cannot be drawn falls back to its payload as text.
///
/// `networkImage` and `localImage` give the image as a widget, for an app
/// that wraps it, to bound its size for one, before drawing it with
/// `widgetRun`.
abstract final class NaturalBlockImages {
  /// Draws `image(<url>)` by fetching it.
  static RunRendering? network(CustomRun run) => _drawn(networkImage(run));

  /// Draws `image(<path>)` or `image(file:...)` by reading the file. Declines
  /// where there is no `dart:io`, the web.
  static RunRendering? local(CustomRun run) => _drawn(localImage(run));

  /// The image `network` draws, or null where it declines.
  static Widget? networkImage(CustomRun run) {
    final source = sourceOf(run.text);
    if (source == null || kindOf(source) != ImageSourceKind.network) {
      return null;
    }

    return _stepped(
      run,
      Image.network(
        source,
        fit: BoxFit.contain,
        semanticLabel: source,
        errorBuilder: (_, _, _) => Text(run.text, style: run.style),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox.square(dimension: run.style.fontSize! / _stepOf(run)),
      ),
    );
  }

  /// The image `local` draws, or null where it declines. [path] reads a file
  /// the app resolved from the payload, a relative one for instance; an image
  /// that cannot be drawn still shows the payload as written.
  static Widget? localImage(CustomRun run, {String? path}) {
    final source = path ?? sourceOf(run.text);
    if (source == null || kindOf(source) != ImageSourceKind.file) return null;

    final image = localFileImage(
      source,
      errorBuilder: (_, _, _) => Text(run.text, style: run.style),
    );
    return image == null ? null : _stepped(run, image);
  }

  static RunRendering? _drawn(Widget? image) =>
      image == null ? null : widgetRun(image);

  static double _stepOf(CustomRun run) =>
      run.theme.fontScaleFor(run.decoration.sizeOffset);

  static Widget _stepped(CustomRun run, Widget image) =>
      _Stepped(factor: _stepOf(run), child: image);

  static const String _prefix = 'image(';

  /// What an `image(...)` payload names, or null when it is not one exactly:
  /// an empty `image()` and any surrounding whitespace are declined, not
  /// trimmed away.
  static String? sourceOf(String text) {
    if (!text.startsWith(_prefix) || !text.endsWith(')')) return null;

    final source = text.substring(_prefix.length, text.length - 1);
    return source.isEmpty || source != source.trim() ? null : source;
  }

  /// Where a source points: a network URL, a local file, or a path relative to
  /// something only the app knows.
  static ImageSourceKind kindOf(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) return ImageSourceKind.relative;

    // `Uri` reads `C:/Users/a.png` as scheme `c`, and no registered scheme
    // is one letter, so a one-letter scheme is a drive.
    if (uri.scheme.length == 1 || uri.scheme == 'file') {
      return ImageSourceKind.file;
    }
    if (uri.hasScheme) return ImageSourceKind.network;

    // Rooted with no scheme is this machine's, UNC included. Unrooted
    // needs a base only the app has.
    return uri.hasAbsolutePath
        ? ImageSourceKind.file
        : ImageSourceKind.relative;
  }
}

/// An image at [factor] times the size it takes where it stands, its own
/// size or less, so a `:-` shows even on an image its space has already
/// shrunk. It never grows past that space.
class _Stepped extends SingleChildRenderObjectWidget {
  final double factor;

  const _Stepped({required this.factor, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStepped(factor);

  @override
  void updateRenderObject(BuildContext context, _RenderStepped renderObject) {
    renderObject.factor = factor;
  }
}

class _RenderStepped extends RenderProxyBox {
  _RenderStepped(this._factor);

  double _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsLayout();
  }

  Size _sizeWithin(BoxConstraints constraints, RenderBox child) =>
      constraints.constrainSizeAndAttemptToPreserveAspectRatio(
        child.getDryLayout(constraints.loosen()) * _factor,
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) => switch (child) {
    final child? => _sizeWithin(constraints, child),
    null => constraints.smallest,
  };

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    size = _sizeWithin(constraints, child);
    child.layout(BoxConstraints.tight(size));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(height) * _factor;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) * _factor;

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) * _factor;
}
