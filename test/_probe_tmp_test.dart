import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';
import 'rendered_spans.dart';

void main() {
  testWidgets('祖先の大きさが変わったとき :+ は追従するか', (tester) async {
    Future<void> pump(double size) => tester.pumpWidget(
      MaterialApp(
        home: DefaultTextStyle(
          style: TextStyle(fontSize: size, color: const Color(0xFF000000)),
          child: const NaturalBlockView(source: ':+大きい文字'),
        ),
      ),
    );

    await pump(14);
    debugPrint('RESULT 祖先 14 のとき :+ の大きさ = '
        '${renderedSpans(tester).first.style!.fontSize}');

    await pump(30);
    debugPrint('RESULT 祖先 30 のとき :+ の大きさ = '
        '${renderedSpans(tester).first.style!.fontSize}');
  });
}
