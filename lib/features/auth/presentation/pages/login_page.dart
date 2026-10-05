import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_lock_cubit.dart';
import '../../../../app/routes.dart';
import '../../../../app/session_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../../../experience/presentation/components/fx_rates_component.dart';
import '../../../fx/presentation/fx_cubit.dart';
import '../bloc/login_bloc.dart';

/// Login: franja de marca arriba y una tarjeta abajo con el saludo, las dos
/// formas de entrar (biometría y usuario/contraseña) y accesos públicos
/// (abrir cuenta, tipo de cambio, ayuda).
class LoginPage extends StatelessWidget {
  const LoginPage({this.savedName, this.fx, super.key});

  /// Nombre del cliente con sesión guardada (para "Hola, Ana").
  final Future<String?> Function()? savedName;

  /// Crea el estado del tipo de cambio (acceso público del login).
  final FxCubit Function()? fx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => curr.status == LoginStatus.success,
      listener: (context, state) {
        unawaited(context.read<SessionCubit>().authenticated(state.session!));
        // Entrar con contraseña también desbloquea una sesión guardada.
        context.read<AppLockCubit>().passwordSignedIn();
      },
      child: Scaffold(
        backgroundColor: dark ? NexoColors.splashDark : NexoColors.primary,
        // La tarjeta queda abajo y la franja de marca ocupa el resto; si el
        // contenido no cabe (pantallas bajas, texto grande, teclado) todo
        // hace scroll en vez de desbordarse.
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BrandHeader(onHelp: () => _showHelp(context)),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Spacing.lg,
                              Spacing.lg,
                              Spacing.lg,
                              Spacing.md,
                            ),
                            child: _LoginCard(
                              savedName: savedName,
                              onFx: fx == null
                                  ? null
                                  : () => _showFx(context, fx!),
                              onHelp: () => _showHelp(context),
                            ),
                          ),
                        ),
                      ),
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

  static void _showHelp(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _HelpSheet(),
  );

  static void _showFx(BuildContext context, FxCubit Function() fx) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => BlocProvider(
          create: (_) => fx(),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.lg),
            child: FxRatesComponent(
              base: 'USD',
              symbols: ['EUR', 'COP', 'PEN', 'MXN'],
            ),
          ),
        ),
      );
}

/// Franja superior con el logo de Nexo.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // En pantallas bajas (≈640 dp) la franja se compacta para que el login
    // completo entre sin scroll.
    final compact = MediaQuery.sizeOf(context).height < 720;
    final logo = compact ? 48.0 : 72.0;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: l10n.help,
              onPressed: onHelp,
              icon: const Icon(Icons.support_agent, color: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: compact ? 0 : Spacing.lg,
              bottom: compact ? Spacing.lg : Spacing.xl,
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/branding/logo_white.png',
                  width: logo,
                  height: logo,
                  semanticLabel: l10n.appTitle,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.appTitle,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.titleLarge
                              : Theme.of(context).textTheme.headlineSmall)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard({
    required this.savedName,
    required this.onFx,
    required this.onHelp,
  });

  final Future<String?> Function()? savedName;
  final VoidCallback? onFx;
  final VoidCallback onHelp;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _biometricFailed = false;

  /// Con sesión guardada se muestran primero los dos botones; el formulario
  /// aparece al elegir "Usuario y contraseña".
  bool _showForm = false;
  Future<String?>? _name;

  @override
  void initState() {
    super.initState();
    _name = widget.savedName?.call();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginBloc>().add(
      LoginSubmitted(username: _username.text, password: _password.text),
    );
  }

  Future<void> _biometricLogin() async {
    setState(() => _biometricFailed = false);
    final ok = await context.read<AppLockCubit>().unlock(
      reason: context.l10n.biometricUnlockReason,
    );
    if (mounted && !ok) setState(() => _biometricFailed = true);
  }

  static String _errorText(AppLocalizations l10n, LoginState state) =>
      switch (state.error) {
        LoginError.locked => l10n.loginLocked,
        LoginError.invalidCredentials => l10n.loginInvalidCredentials,
        _ => state.failure?.localized(l10n) ?? l10n.errorUnexpected,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // Hay una sesión guardada y la biometría está activada.
    final canUseBiometrics = context.select(
      (AppLockCubit c) =>
          c.state.locked && c.state.enabled && c.state.available,
    );
    final expired = context.select(
      (SessionCubit c) =>
          c.state is SessionUnauthenticated &&
          (c.state as SessionUnauthenticated).expired,
    );
    final showForm = !canUseBiometrics || _showForm;

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Saludo: con sesión guardada, por nombre.
            FutureBuilder<String?>(
              future: canUseBiometrics ? _name : null,
              builder: (context, snapshot) => Text(
                snapshot.data == null
                    ? l10n.loginWelcome
                    : l10n.loginHello(snapshot.data!),
                key: const Key('login_greeting'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: Spacing.md),
            if (expired && state.status == LoginStatus.initial) ...[
              InlineMessage(
                message: l10n.loginSessionExpired,
                kind: InlineMessageKind.info,
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (state.status == LoginStatus.failure) ...[
              InlineMessage(
                key: const Key('login_error'),
                message: _errorText(l10n, state),
                kind: state.error == LoginError.locked
                    ? InlineMessageKind.warning
                    : InlineMessageKind.error,
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (_biometricFailed) ...[
              InlineMessage(
                key: const Key('login_biometric_error'),
                message: l10n.lockedFailed,
              ),
              const SizedBox(height: Spacing.md),
            ],
            if (!showForm) ...[
              // Las dos formas de entrar.
              FilledButton.icon(
                key: const Key('login_biometric'),
                onPressed: _biometricLogin,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.biometricLogin),
              ),
              const SizedBox(height: Spacing.sm),
              OutlinedButton.icon(
                key: const Key('login_show_password'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(kMinTouchTarget + 4),
                ),
                onPressed: () => setState(() => _showForm = true),
                icon: const Icon(Icons.person_outline),
                label: Text(l10n.loginWithPassword),
              ),
            ] else
              Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('login_username'),
                        label: l10n.usernameLabel,
                        controller: _username,
                        prefixIcon: Icons.person_outline,
                        enabled: !state.isSubmitting,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: LoginValidators(l10n).username,
                      ),
                      const SizedBox(height: Spacing.md),
                      AppTextField(
                        key: const Key('login_password'),
                        label: l10n.passwordLabel,
                        controller: _password,
                        prefixIcon: Icons.lock_outline,
                        obscure: true,
                        enabled: !state.isSubmitting,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: LoginValidators(l10n).password,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: Spacing.lg),
                      PrimaryButton(
                        key: const Key('login_submit'),
                        label: l10n.loginSubmit,
                        loading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                      if (canUseBiometrics)
                        TextButton.icon(
                          onPressed: state.isSubmitting
                              ? null
                              : () => setState(() => _showForm = false),
                          icon: const Icon(Icons.fingerprint),
                          label: Text(l10n.biometricLogin),
                        ),
                    ],
                  ),
                ),
              ),
            if (canUseBiometrics)
              // Otra persona usa el teléfono: se cierra la sesión guardada
              // del todo (se revoca en el backend).
              TextButton(
                key: const Key('login_use_another_account'),
                onPressed: () => context.read<SessionCubit>().logout(),
                child: Text(l10n.useAnotherAccount),
              ),
            const SizedBox(height: Spacing.md),
            // Accesos públicos (todos de la misma altura aunque el texto ocupe
            // dos líneas).
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!canUseBiometrics)
                    _QuickTile(
                      key: const Key('login_create_account'),
                      icon: Icons.person_add_alt,
                      label: l10n.openAccount,
                      onTap: () => context.push(Routes.register),
                    ),
                  if (widget.onFx != null)
                    _QuickTile(
                      key: const Key('login_fx'),
                      icon: Icons.currency_exchange,
                      label: l10n.fxTitle,
                      onTap: widget.onFx!,
                    ),
                  _QuickTile(
                    key: const Key('login_help'),
                    icon: Icons.support_agent,
                    label: l10n.help,
                    onTap: widget.onHelp,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Acceso rápido del pie de la tarjeta.
class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: const BorderRadius.all(Radii.md),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radii.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Spacing.md,
                horizontal: Spacing.xs,
              ),
              child: Column(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: theme.textTheme.labelMedium,
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

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          0,
          Spacing.lg,
          Spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.helpTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Spacing.xs),
            Text(l10n.helpHours, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Spacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(l10n.helpPhone),
              subtitle: const SelectableText('1800-639-600'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.helpEmail),
              subtitle: const SelectableText('ayuda@nexo.ec'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mismos límites que valida ms-auth (`LoginRequest`).
class LoginValidators {
  const LoginValidators(this._l10n);

  static const maxUsername = 30;
  static const maxPassword = 128;

  final AppLocalizations _l10n;

  String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _l10n.usernameRequired;
    if (v.length > maxUsername) return _l10n.maxChars(maxUsername);
    return null;
  }

  String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return _l10n.passwordRequired;
    if (v.length > maxPassword) return _l10n.maxChars(maxPassword);
    return null;
  }
}
