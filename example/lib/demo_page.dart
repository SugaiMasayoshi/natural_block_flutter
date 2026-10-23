import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import 'custom_runs.dart';
import 'playground.dart';
import 'samples.dart';

class NaturalBlockDemoPage extends StatelessWidget {
  final bool dark;
  final bool striped;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<bool> onStripedChanged;

  const NaturalBlockDemoPage({
    super.key,
    this.dark = false,
    this.striped = false,
    this.onDarkChanged = _ignore,
    this.onStripedChanged = _ignore,
  });

  static void _ignore(bool _) {}

  @override
  Widget build(BuildContext context) {
    final theme = NaturalBlockTheme.fromContext(context, striped: striped);

    return Scaffold(
      appBar: AppBar(
        title: const Text('natural_block_flutter example'),
        actions: [
          _Toggle(label: '縞', value: striped, onChanged: onStripedChanged),
          _Toggle(label: 'ダーク', value: dark, onChanged: onDarkChanged),
        ],
      ),
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Playground(theme: theme)),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: samples.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) =>
                    _SampleCard(sample: samples[index], theme: theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final Sample sample;
  final NaturalBlockTheme theme;

  const _SampleCard({required this.sample, required this.theme});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sample.title, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          sample.source,
          style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: NaturalBlockView(
            source: sample.source,
            theme: theme,
            customs: appCustoms,
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
      ],
    );
  }
}
