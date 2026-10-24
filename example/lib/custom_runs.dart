import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import 'quiz.dart';

RunRendering? _links(CustomRun run) => tappableText(
  run,
  onTap: (context) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('タップされたアクション: ${run.text}'))),
);

/// Held as a const list so it compares equal across builds: one written out
/// afresh each time would redraw every line, and lose a tap held across it.
const appCustoms = <RunHandler>[NaturalBlockImages.network, quizChoice, _links];
