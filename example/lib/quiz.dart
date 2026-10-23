import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

final _choice = RegExp(r'^(correct|wrong)\((.+?)(?:\s*→\s*(.+))?\)$');

/// Draws `correct(<label> → <message>)` and `wrong(<label> → <message>)` as a
/// choice that, once tapped, says whether it was right. The message is
/// optional. Unrendered, the payload still reads as the answer it marks.
RunRendering? quizChoice(CustomRun run) {
  final match = _choice.firstMatch(run.text);
  if (match == null) return null;

  return widgetRun(
    _QuizChoice(
      correct: match[1] == 'correct',
      label: match[2]!,
      message: match[3],
      style: run.style,
    ),
  );
}

class _QuizChoice extends StatefulWidget {
  final bool correct;
  final String label;
  final String? message;
  final TextStyle style;

  const _QuizChoice({
    required this.correct,
    required this.label,
    required this.message,
    required this.style,
  });

  @override
  State<_QuizChoice> createState() => _QuizChoiceState();
}

class _QuizChoiceState extends State<_QuizChoice> {
  var _answered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = widget.style.fontSize!;
    final verdict = widget.correct ? Colors.green : colors.error;
    final tint = _answered ? verdict : colors.outline;
    // A choice is not a link: keep the run's size and weight, not the custom
    // marking's colour and underline.
    final text = TextStyle(
      fontSize: size,
      fontWeight: widget.style.fontWeight,
      color: colors.onSurface,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size / 8, vertical: size / 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: _answered
                ? verdict.withValues(alpha: 0.15)
                : Colors.transparent,
            shape: StadiumBorder(side: BorderSide(color: tint, width: 1.5)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => setState(() => _answered = true),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size / 2,
                  vertical: size / 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_answered) ...[
                      Icon(
                        widget.correct ? Icons.check : Icons.close,
                        size: size,
                        color: verdict,
                      ),
                      SizedBox(width: size / 4),
                    ],
                    Flexible(child: Text(widget.label, style: text)),
                  ],
                ),
              ),
            ),
          ),
          if (_answered && widget.message != null)
            Padding(
              padding: EdgeInsets.only(top: size / 6, left: size / 2),
              child: Text(
                widget.message!,
                style: text.copyWith(color: verdict, fontSize: size * 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
