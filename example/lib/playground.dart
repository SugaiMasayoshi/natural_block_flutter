import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import 'custom_runs.dart';

class Playground extends StatefulWidget {
  final NaturalBlockTheme theme;

  const Playground({super.key, required this.theme});

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  final _controller = TextEditingController(
    text:
        ':!*自由に書き換えて試してみよう:!:*\n'
        ':+++大きく:--標準に戻す\n'
        '左のセル^右のセル\n'
        ':@ここをタップ:@ するとSnackBarが出る',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colors.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('試してみよう', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 12,
            minLines: 4,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              hintText: '記法を入力...',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => NaturalBlockView(
                source: _controller.text,
                theme: widget.theme,
                customs: appCustoms,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
