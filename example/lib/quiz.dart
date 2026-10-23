import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

final _choice = RegExp(r'^(correct|wrong)\((.+?)(?:\s*→\s*(.+))?\)$');

/// Draws `correct(<label> → <message>)` and `wrong(<label> → <message>)` as a
/// choice that says whether it was right while it is open. The message is
/// optional. Unrendered, the payload still reads as the answer it marks.
RunRendering? quizChoice(CustomRun run) {
  final match = _choice.firstMatch(run.text);
  if (match == null) return null;

  return widgetRun(
    _QuizChoice(
      correct: match[1] == 'correct',
      label: match[2]!,
      message: match[3],
      fontSize: run.style.fontSize!,
    ),
  );
}

class _QuizChoice extends StatefulWidget {
  final bool correct;
  final String label;
  final String? message;
  final double fontSize;

  const _QuizChoice({
    required this.correct,
    required this.label,
    required this.message,
    required this.fontSize,
  });

  @override
  State<_QuizChoice> createState() => _QuizChoiceState();
}

class _QuizChoiceState extends State<_QuizChoice> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final verdict = widget.correct
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChip(
          label: Text(
            widget.label,
            style: TextStyle(fontSize: widget.fontSize),
          ),
          selected: _open,
          onSelected: (open) => setState(() => _open = open),
          selectedColor: verdict.withValues(alpha: 0.15),
          showCheckmark: false,
          avatar: _open
              ? Icon(widget.correct ? Icons.check : Icons.close, color: verdict)
              : null,
        ),
        if (_open && widget.message != null)
          Text(
            widget.message!,
            style: TextStyle(color: verdict, fontSize: widget.fontSize * 0.7),
          ),
      ],
    );
  }
}
