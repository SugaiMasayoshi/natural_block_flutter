import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

/// Reached by key rather than by a `BuildContext`: a handler has none, and what
/// a tap means belongs to the app.
final messenger = GlobalKey<ScaffoldMessengerState>();

void _announce(String text) => messenger.currentState?.showSnackBar(
  SnackBar(content: Text('タップされたアクション: $text')),
);

RunRendering? _links(CustomRun run) =>
    tappableText(run.text, run.style, onTap: _announce);

/// Held as a const list so it compares equal across builds: one written out
/// afresh each time would redraw every line, and lose a tap held across it.
const appCustoms = <RunHandler>[NaturalBlockImages.network, _links];
