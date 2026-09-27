// 【解説】 読む順番 1/12: パッケージの入口。利用者が import するのはこのファイルだけ。
// 【解説】 中身は export の一覧で、ここに並んだものが公開 API になる。
// 【解説】 読む順番: 1 これ → 2 natural_block_view → 3 natural_block_registry
// 【解説】 → 4 default_builders → 5 column_node_view → 6 horizontal_align_layout
// 【解説】 → 7 row_node_view → 8 text_node_view → 9 raw_node_view
// 【解説】 → 10 table_node_view → 11 natural_block_theme → 12 natural_block_images
// 【解説】 名前の無い library 宣言。ファイルをライブラリとして明示するだけで、動作には影響しない。
library;

// 【解説】 export: このファイルを import した人に、指定したファイルの公開名をそのまま見せる。
// 【解説】 src/ の下は「非公開の置き場」という慣習なので、見せたいものだけをここで選ぶ。
export 'src/registry/default_builders.dart';
export 'src/registry/natural_block_registry.dart';
export 'src/widget/column_node_view.dart';
export 'src/widget/natural_block_images.dart';
export 'src/widget/natural_block_theme.dart';
export 'src/widget/natural_block_view.dart';
export 'src/widget/raw_node_view.dart';
export 'src/widget/row_node_view.dart';
export 'src/widget/table_node_view.dart';
export 'src/widget/text_node_view.dart';
