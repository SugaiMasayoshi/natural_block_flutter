import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

/// Draws `correct(<label>→<message>)` and `wrong(<label>→<message>)` as a
/// choice that says whether it was right while it is open. The message is
/// optional. Unrendered, the payload still reads as the answer it marks.
RunRendering? quizChoice(CustomRun run) {
  final correct = run.argumentOf('correct');
  final argument = correct ?? run.argumentOf('wrong');
  if (argument == null) return null;

  final arrow = argument.indexOf('→');
  final label = arrow < 0 ? argument : argument.substring(0, arrow);
  final message = arrow < 0 ? null : argument.substring(arrow + 1);

  return widgetRun(
    _QuizChoice(
      correct: correct != null,
      label: label,
      message: message,
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
    final size = widget.fontSize;
    final verdict = widget.correct
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: size / 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChoiceChip(
            label: ConstrainedBox(
              constraints: BoxConstraints(minWidth: size * 4),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: size / 2,
              vertical: size / 4,
            ),
            selected: _open,
            onSelected: (open) => setState(() => _open = open),
            selectedColor: verdict.withValues(alpha: 0.15),
            showCheckmark: false,
            avatar: _open
                ? Icon(
                    widget.correct ? Icons.check : Icons.close,
                    color: verdict,
                  )
                : null,
          ),
          if (_open && widget.message != null)
            Padding(
              padding: EdgeInsets.only(top: size / 4, left: size / 2),
              child: Text(
                widget.message!,
                style: TextStyle(color: verdict, fontSize: size * 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
