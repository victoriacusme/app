import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session_cubit.dart';
import '../../../../design_system/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  semanticLabel: 'Nexo Bank',
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Bienvenido a Nexo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.xl),
                if (expired && state.status == LoginStatus.initial) ...[
                  const InlineMessage(
                    message: 'Tu sesión expiró. Ingresa nuevamente.',
                    kind: InlineMessageKind.info,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                if (state.status == LoginStatus.failure) ...[
                  InlineMessage(
                    key: const Key('login_error'),
                    message: state.message!,
                    kind: state.error == LoginError.locked
                        ? InlineMessageKind.warning
                        : InlineMessageKind.error,
                  ),
                  const SizedBox(height: Spacing.md),
                ],
                AppTextField(
                  key: const Key('login_username'),
                  label: 'Usuario',
                  controller: _username,
                  prefixIcon: Icons.person_outline,
                  enabled: !state.isSubmitting,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: LoginValidators.username,
                ),
                const SizedBox(height: Spacing.md),
                AppTextField(
                  key: const Key('login_password'),
                  label: 'Contraseña',
                  controller: _password,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  enabled: !state.isSubmitting,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: LoginValidators.password,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Spacing.lg),
                PrimaryButton(
                  key: const Key('login_submit'),
                  label: 'Ingresar',
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
abstract final class LoginValidators {
  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu usuario';
    if (v.length > 30) return 'Máximo 30 caracteres';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length > 128) return 'Máximo 128 caracteres';
    return null;
  }
}
