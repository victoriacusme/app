import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_lock_cubit.dart';
import '../../../app/session_cubit.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/domain_l10n.dart';
import '../../../l10n/l10n.dart';
import '../domain/customer_profile.dart';
import 'profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          curr.saveFailure != null && prev.saveFailure != curr.saveFailure,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.saveFailed(state.saveFailure!.localized(context.l10n)),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) => switch (state.status) {
            ProfileStatus.loading => Center(
              child: CircularProgressIndicator(semanticsLabel: l10n.loading),
            ),
            ProfileStatus.failure => ErrorView(
              message: state.failure!.localized(l10n),
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
    final l10n = context.l10n;
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
            child: Chip(
              label: Text(l10n.customerSegment(profile.segment.label(l10n))),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l10n.idNumberLabel),
                subtitle: Text(profile.maskedIdNumber),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.emailTitle),
                subtitle: Text(profile.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(l10n.phoneTitle),
                subtitle: Text(profile.maskedPhone),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Semantics(
          header: true,
          child: Text(l10n.preferences, style: theme.textTheme.titleMedium),
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
                    Text(l10n.theme),
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemePreference>(
                        key: const Key('profile_theme'),
                        // Sin íconos: con 3 opciones el texto no cabe en
                        // pantallas angostas (360 dp).
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemePreference.light,
                            label: Text(l10n.themeLight),
                          ),
                          ButtonSegment(
                            value: ThemePreference.dark,
                            label: Text(l10n.themeDark),
                          ),
                          ButtonSegment(
                            value: ThemePreference.system,
                            label: Text(l10n.themeSystem),
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
                title: Text(l10n.language),
                trailing: DropdownButton<String>(
                  key: const Key('profile_language'),
                  value: prefs.language,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: 'es',
                      child: Text(l10n.languageSpanish),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.languageEnglish),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) edit(prefs.copyWith(language: v));
                  },
                ),
              ),
              SwitchListTile(
                key: const Key('profile_notifications'),
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l10n.notifications),
                subtitle: Text(l10n.notificationsSubtitle),
                value: prefs.notificationsEnabled,
                onChanged: (v) => edit(prefs.copyWith(notificationsEnabled: v)),
              ),
              SwitchListTile(
                key: const Key('profile_promotions'),
                secondary: const Icon(Icons.local_offer_outlined),
                title: Text(l10n.promotions),
                subtitle: Text(l10n.promotionsSubtitle),
                value: prefs.showPromotions,
                onChanged: (v) => edit(prefs.copyWith(showPromotions: v)),
              ),
            ],
          ),
        ),
        const _BiometricSection(),
        const SizedBox(height: Spacing.lg),
        OutlinedButton.icon(
          key: const Key('profile_logout'),
          onPressed: () => context.read<SessionCubit>().logout(),
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
        ),
      ],
    );
  }
}

/// Preferencia local del dispositivo: pedir biometría al volver a entrar.
class _BiometricSection extends StatelessWidget {
  const _BiometricSection();

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockCubit>().state;
    final l10n = context.l10n;
    if (!lock.available) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg),
      child: Card(
        margin: EdgeInsets.zero,
        child: SwitchListTile(
          key: const Key('profile_biometrics'),
          secondary: const Icon(Icons.fingerprint),
          title: Text(l10n.biometricToggle),
          subtitle: Text(l10n.biometricToggleSubtitle),
          value: lock.enabled,
          onChanged: (v) => context.read<AppLockCubit>().setEnabled(
            enabled: v,
            reason: l10n.biometricEnableReason,
          ),
        ),
      ),
    );
  }
}
