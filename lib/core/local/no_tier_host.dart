/// 本地版：没有订阅档位需要与服务端对账，这里保持同名容器做透传。
library;

import 'package:flutter/widgets.dart';

class TierReconcileHost extends StatelessWidget {
  const TierReconcileHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
