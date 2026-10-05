import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/experience_layout.dart';
import '../localized_text.dart';

class PromoBannerComponent extends StatelessWidget {
  const PromoBannerComponent({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.deeplink,
    super.key,
  });

  factory PromoBannerComponent.fromSpec(ComponentSpec spec) =>
      PromoBannerComponent(
        title: LocalizedText.parse(spec.properties['title']),
        subtitle: LocalizedText.tryParse(spec.properties['subtitle']),
        imageUrl: spec.properties['imageUrl'] as String?,
        deeplink: spec.properties['deeplink'] as String?,
      );

  final LocalizedText title;
  final LocalizedText? subtitle;
  final String? imageUrl;
  final String? deeplink;

  /// Las promociones conocidas (por su destino) usan el texto traducido de
  /// la app. Una campaña nueva que la app aún no conoce muestra el texto del
  /// backend (o el de su idioma, si llega por idioma).
  (String, String?) texts(AppLocalizations l10n) {
    final amount = NumberFormat('#,##0', l10n.localeName).format(5000);
    return switch (deeplink) {
      'app://savings' => (l10n.promoSavingsTitle, l10n.promoSavingsSubtitle),
      'app://advisor' => (l10n.promoAdvisorTitle, l10n.promoAdvisorSubtitle),
      'app://credit' => (
        l10n.promoCreditTitle,
        l10n.promoCreditSubtitle('\$$amount'),
      ),
      'app://transfers' => (
        l10n.promoTransfersTitle,
        l10n.promoTransfersSubtitle,
      ),
      _ => (title.resolve(l10n.localeName), subtitle?.resolve(l10n.localeName)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (title, subtitle) = texts(l10n);
    // Fondo de marca: se ve mientras carga la imagen o si falla.
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Semantics(
        button: deeplink != null,
        label: l10n.promoSemantics(
          subtitle == null ? title : '$title. $subtitle',
        ),
        excludeSemantics: true,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: deeplink == null
                ? null
                : () => DeepLinks.open(context, deeplink!),
            child: AspectRatio(
              aspectRatio: 5 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl == null)
                    placeholder
                  else
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : placeholder,
                    ),
                  // Degradado para asegurar contraste del texto sobre la foto.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
