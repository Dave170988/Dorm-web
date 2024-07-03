import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../utils/string_util.dart';

PreferredSizeWidget appBarWidget(
    {bool hasLeading = false, List<Widget>? actions}) {
  return AppBar(
      automaticallyImplyLeading: hasLeading,
      title: Column(
        children: [const Gap(10), Image.asset(ImagePaths.logo, scale: 6)],
      ),
      actions: actions);
}
