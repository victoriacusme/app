import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/session_cubit.dart';
import '../../../design_system/design_system.dart';
import '../domain/customer_profile.dart';
import 'profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          curr.saveFailure != null && prev.saveFailure != curr.saveFailure,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No pudimos guardar el cambio. ${state.saveFailure!.message}',
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) => switch (state.status) {
            ProfileStatus.loading => const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
            ),
            ProfileStatus.failure => ErrorView(
              message: state.failure!.message,
              correlationId: state.failure!.correlationId,
              onRetry: () =>
                  context.read<ProfileBloc>().add(const ProfileRequested()),
            ),
            ProfileStatus.loaded => _ProfileContent(profile: state.profile!),
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = profile.preferences;
    void edit(Preferences next) =>
        context.read<ProfileBloc>().add(PreferencesEdited(next));

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            child: Text(
              profile.firstName.characters.first.toUpperCase(),
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Chip(label: Text('Cliente ${profile.segmentLabel}')),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Cédula'),
                subtitle: Text(profile.maskedIdNumber),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo'),
                subtitle: Text(profile.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Celular'),
                subtitle: Text(profile.maskedPhone),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Semantics(
          header: true,
          child: Text('Preferencias', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema'),
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemePreference>(
                        key: const Key('profile_theme'),
                        segments: const [
                          ButtonSegment(
                            value: ThemePreference.light,
                            label: Text('Claro'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemePreference.dark,
                            label: Text('Oscuro'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemePreference.system,
                            label: Text('Sistema'),
                            icon: Icon(Icons.brightness_auto_outlined),
                          ),
                        ],
                        selected: {prefs.theme},
                        onSelectionChanged: (s) =>
                            edit(prefs.copyWith(theme: s.single)),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Idioma'),
                subtitle: const Text(
                  'Por ahora la app está disponible solo en español',
                ),
                trailing: DropdownButton<String>(
                  value: prefs.language,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {
                    if (v != null) edit(prefs.copyWith(language: v));
                  },
                ),
              ),
              SwitchListTile(
                key: const Key('profile_notifications'),
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Notificaciones'),
                subtitle: const Text('Avisos de tus transferencias'),
                value: prefs.notificationsEnabled,
                onChanged: (v) => edit(prefs.copyWith(notificationsEnabled: v)),
              ),
              SwitchListTile(
                key: const Key('profile_promotions'),
                secondary: const Icon(Icons.local_offer_outlined),
                title: const Text('Promociones'),
                subtitle: const Text('Ver ofertas en tu inicio'),
                value: prefs.showPromotions,
                onChanged: (v) => edit(prefs.copyWith(showPromotions: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton.icon(
          key: const Key('profile_logout'),
          onPressed: () => context.read<SessionCubit>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
