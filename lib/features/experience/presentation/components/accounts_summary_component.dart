import 'package:flutter/widgets.dart';

import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/widgets/accounts_section.dart';
import '../../domain/experience_layout.dart';

/// Resumen de cuentas. El título ("Tus cuentas") lo define la app, no el
/// backend; de las props solo se usa `showTotal`.
class AccountsSummaryComponent extends StatelessWidget {
  const AccountsSummaryComponent({required this.showTotal, super.key});

  factory AccountsSummaryComponent.fromSpec(ComponentSpec spec) =>
      AccountsSummaryComponent(
        showTotal: spec.properties['showTotal'] as bool? ?? false,
      );

  final bool showTotal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.sm),
    child: AccountsSection(showTotal: showTotal),
  );
}
