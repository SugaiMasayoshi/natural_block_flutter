# natural_block_flutter example

## The smallest use

```dart
import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() => runApp(const MaterialApp(home: Scaffold(body: Notes())));

// A custom run starting with https:// becomes a tap.
RunRendering? links(CustomRun run) {
  if (!run.text.startsWith('https://')) return null;
  return tappableText(
    run,
    onTap: (context) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(run.text))),
  );
}

class Notes extends StatelessWidget {
  const Notes({super.key});

  @override
  Widget build(BuildContext context) => const SelectionArea(
    child: NaturalBlockView(
      source:
          '=:++*Release notes\n'
          '<:%Fixed:% a crash on start. C++ and 100% need no escaping.\n'
          'Details: :@https://example.com:@\n'
          '^<Item^>Price^\n'
          '^Apple^>100^',
      customs: [links, NaturalBlockImages.network],
    ),
  );
}
```

## The demo app

This folder is also a demo app with two parts:

* **Playground** -- type markup at the top and see it rendered live.
* **Sample gallery** -- snippets of every construct beside how they render:
  tones, size steps, punctuation that needs no escaping, escaping, rows,
  alignment, custom runs, tables and images.

It wires up the optional pieces so they can be seen working: images, a tap
handler built on `tappableText`, a `SelectionArea`, and a theme from the app's
`ColorScheme` that switches between light and dark, and plain and striped
tables.

```bash
cd example
flutter run
```
