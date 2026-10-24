import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'demo_page.dart';

void main() {
  runApp(const MyApp());
}

@Preview(name: 'natural_block_flutter サンプル一覧')
Widget naturalBlockSamplesPreview() => const NaturalBlockDemoPage();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _dark = false;
  var _striped = false;

  static ThemeData _themed(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 28)),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'natural_block_flutter example',
      theme: _themed(Brightness.light),
      darkTheme: _themed(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: NaturalBlockDemoPage(
        dark: _dark,
        striped: _striped,
        onDarkChanged: (value) => setState(() => _dark = value),
        onStripedChanged: (value) => setState(() => _striped = value),
      ),
    );
  }
}
