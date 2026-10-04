import 'package:flutter/material.dart';

import '../../../../core/navigation/deep_links.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/experience_layout.dart';

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
        title: spec.properties['title'] as String,
        subtitle: spec.properties['subtitle'] as String?,
        imageUrl: spec.properties['imageUrl'] as String?,
        deeplink: spec.properties['deeplink'] as String?,
      );

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? deeplink;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
        label: 'Promoción: $title${subtitle == null ? '' : '. $subtitle'}',
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
                            subtitle!,
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
