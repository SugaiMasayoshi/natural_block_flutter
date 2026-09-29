// 【解説】 読む順番 7/12: 行(^ で区切ったセルの並び)を横に並べて描くウィジェット。
// 【解説】 幅に上限があるときはセルで幅を等分し、無いときは中身の幅のまま並べる。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';

class RowNodeView extends StatelessWidget {
  final RowNode node;

  final NaturalBlockScope scope;

  const RowNodeView({super.key, required this.node, required this.scope});

  @override
  Widget build(BuildContext context) {
    // 【解説】 各セル(ColumnNode)を対応表経由でウィジェットにする。独自の描き方もセルに効く。
    final cells = scope.buildLayouts(context, node.children);

    // 【解説】 LayoutBuilder: 親から与えられた大きさの制約を見てから、中身を決めるウィジェット。
    return LayoutBuilder(
      builder: (context, constraints) {
        // 【解説】 幅に上限があるか。横スクロールの中などでは上限が無い(無限)。
        final bounded = constraints.hasBoundedWidth;
        return Row(
          // 【解説】 セルの上端を揃える。
          crossAxisAlignment: CrossAxisAlignment.start,
          // 【解説】 ? : は三項演算子。上限があれば横幅いっぱい、無ければ中身の幅。
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // 【解説】 collection-for の中に collection-if。条件でリストに入れる要素を選ぶ。
            // 【解説】 Expanded は残りの幅を等分する。上限の無い幅では等分できず例外になるので、
            // 【解説】 そのときはセルをそのまま入れる。
            for (final cell in cells)
              if (bounded) Expanded(child: cell) else cell,
          ],
        );
      },
    );
  }
}
