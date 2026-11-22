/// 本地版：查词面板不再显示积分余额（没有积分体系）。
library;

import 'package:flutter/material.dart';

class LookupCreditsChip extends StatelessWidget {
  const LookupCreditsChip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
