import 'package:flutter/widgets.dart';

import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/widgets/accounts_section.dart';
import '../../domain/experience_layout.dart';

class AccountsSummaryComponent extends StatelessWidget {
  const AccountsSummaryComponent({
    required this.title,
    required this.showTotal,
    super.key,
  });

  factory AccountsSummaryComponent.fromSpec(ComponentSpec spec) =>
      AccountsSummaryComponent(
        title: spec.properties['title'] as String? ?? 'Tus cuentas',
        showTotal: spec.properties['showTotal'] as bool? ?? false,
      );

  final String title;
  final bool showTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.sm),
    child: AccountsSection(title: title, showTotal: showTotal),
  );
}
