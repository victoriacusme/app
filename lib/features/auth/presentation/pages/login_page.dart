import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/login_bloc.dart';
import '../onboarding/onboarding_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => curr.status == LoginStatus.success,
      listener: (context, state) =>
          context.read<SessionCubit>().authenticated(state.session!),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const _LoginForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

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
    final validators = LoginValidators(l10n);
    final expired = context.select(
      (SessionCubit c) =>
          c.state is SessionUnauthenticated &&
          (c.state as SessionUnauthenticated).expired,
    );

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.account_balance,
                  size: 56,
                  color: theme.colorScheme.primary,
                  semanticLabel: l10n.appTitle,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.loginWelcome,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.xl),
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
                AppTextField(
                  key: const Key('login_username'),
                  label: l10n.usernameLabel,
                  controller: _username,
                  prefixIcon: Icons.person_outline,
                  enabled: !state.isSubmitting,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: validators.username,
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
                  validator: validators.password,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Spacing.lg),
                PrimaryButton(
                  key: const Key('login_submit'),
                  label: l10n.loginSubmit,
                  loading: state.isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: Spacing.sm),
                const CreateAccountLink(),
              ],
            ),
          ),
        );
      },
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
