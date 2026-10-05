import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(semanticsLabel: context.l10n.loading),
      ),
    );
  }
}
