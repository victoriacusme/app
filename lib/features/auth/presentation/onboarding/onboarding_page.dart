import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/session_cubit.dart';
import '../../../../design_system/design_system.dart';
import 'onboarding_cubit.dart';

/// Registro en pasos con barra de progreso.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _titles = {
    OnboardingStep.personal: 'Tus datos',
    OnboardingStep.credentials: 'Tu usuario',
    OnboardingStep.terms: 'Términos',
    OnboardingStep.welcome: 'Bienvenido',
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final state = context.watch<OnboardingCubit>().state;
    final step = state.step;
    return PopScope(
      canPop: step == OnboardingStep.personal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[step]!),
          automaticallyImplyLeading: step != OnboardingStep.welcome,
          leading:
              step == OnboardingStep.personal || step == OnboardingStep.welcome
              ? null
              : BackButton(onPressed: cubit.back),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.sm,
              ),
              child: Semantics(
                label:
                    'Paso ${step.index + 1} de '
                    '${OnboardingStep.values.length}',
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: state.progress,
                        borderRadius: const BorderRadius.all(Radii.sm),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text('${step.index + 1}/${OnboardingStep.values.length}'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: switch (step) {
                OnboardingStep.personal => const _PersonalStep(),
                OnboardingStep.credentials => const _CredentialsStep(),
                OnboardingStep.terms => const _TermsStep(),
                OnboardingStep.welcome => const _WelcomeStep(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Estructura común: contenido desplazable + mensaje de error + botón.
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.children, this.buttonLabel = 'Continuar'});

  final List<Widget> children;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        if (state.failureMessage != null) ...[
          InlineMessage(
            key: const Key('onboarding_error'),
            message: state.failureMessage!,
          ),
          const SizedBox(height: Spacing.md),
        ],
        ...children,
        const SizedBox(height: Spacing.lg),
        PrimaryButton(
          key: const Key('onboarding_next'),
          label: buttonLabel,
          loading: state.submitting,
          onPressed: () {
            FocusScope.of(context).unfocus();
            context.read<OnboardingCubit>().next();
          },
        ),
      ],
    );
  }
}

/// Campo de texto conectado al cubit.
class _Field extends StatefulWidget {
  const _Field(
    this.field, {
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.autofillHints,
    this.inputFormatters,
    this.helperText,
    this.isLast = false,
  });

  final OnboardingField field;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;
  final bool isLast;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(
    text: context.read<OnboardingCubit>().state.value(widget.field),
  );
  late bool _hidden = widget.obscure;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = context.select(
      (OnboardingCubit c) => c.state.visibleError(widget.field),
    );
    final enabled = !context.select((OnboardingCubit c) => c.state.submitting);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: TextField(
        key: Key('onboarding_${widget.field.name}'),
        controller: _controller,
        enabled: enabled,
        obscureText: _hidden,
        enableSuggestions: !widget.obscure,
        autocorrect: false,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.isLast
            ? TextInputAction.done
            : TextInputAction.next,
        onChanged: (v) =>
            context.read<OnboardingCubit>().changed(widget.field, v),
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helperText,
          helperMaxLines: 2,
          errorText: error,
          errorMaxLines: 2,
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final birthDate = state.birthDate;
    final birthError = state.visibleError(OnboardingField.birthDate);
    return _StepLayout(
      children: [
        const _Field(
          OnboardingField.fullName,
          label: 'Nombre completo',
          keyboardType: TextInputType.name,
          autofillHints: [AutofillHints.name],
        ),
        _Field(
          OnboardingField.idNumber,
          label: 'Cédula',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: InkWell(
            key: const Key('onboarding_birthDate'),
            borderRadius: const BorderRadius.all(Radii.md),
            onTap: () => _pickDate(context, birthDate),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                errorText: birthError,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                birthDate == null
                    ? ''
                    : '${birthDate.day.toString().padLeft(2, '0')}/'
                          '${birthDate.month.toString().padLeft(2, '0')}/'
                          '${birthDate.year}',
              ),
            ),
          ),
        ),
        const _Field(
          OnboardingField.email,
          label: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
          autofillHints: [AutofillHints.email],
        ),
        _Field(
          OnboardingField.phone,
          label: 'Celular',
          helperText: 'Ejemplo: 0991234567 o +593991234567',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
          ],
          isLast: true,
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime? current) async {
    final cubit = context.read<OnboardingCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) cubit.birthDateChanged(picked);
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep();

  @override
  Widget build(BuildContext context) {
    return const AutofillGroup(
      child: _StepLayout(
        children: [
          _Field(
            OnboardingField.username,
            label: 'Usuario',
            helperText: 'Lo usarás para ingresar. Letras, números, "." o "_".',
            autofillHints: [AutofillHints.newUsername],
          ),
          _Field(
            OnboardingField.password,
            label: 'Contraseña',
            helperText:
                'Mínimo 8 caracteres, con al menos una letra y un número.',
            obscure: true,
            autofillHints: [AutofillHints.newPassword],
          ),
          _Field(
            OnboardingField.confirmation,
            label: 'Confirma la contraseña',
            obscure: true,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TermsStep extends StatelessWidget {
  const _TermsStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final theme = Theme.of(context);
    final error = state.visibleError(OnboardingField.terms);
    return _StepLayout(
      buttonLabel: 'Crear mi cuenta',
      children: [
        Text('Antes de terminar', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: Text(
              'Al crear tu cuenta, Nexo Bank abrirá a tu nombre una cuenta de '
              'ahorros sin costo de mantenimiento. Tus datos se usan solo para '
              'identificarte y operar tus productos, se guardan cifrados y no '
              'se comparten con terceros sin tu autorización. Puedes cerrar tu '
              'cuenta en cualquier momento.',
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        CheckboxListTile(
          key: const Key('onboarding_terms'),
          value: state.acceptedTerms,
          onChanged: state.submitting
              ? null
              : (v) => context.read<OnboardingCubit>().termsChanged(
                  accepted: v ?? false,
                ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Acepto los términos y condiciones y la política de privacidad',
          ),
          subtitle: error == null
              ? null
              : Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final theme = Theme.of(context);
    final firstName = state
        .value(OnboardingField.fullName)
        .trim()
        .split(' ')
        .first;
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        const SizedBox(height: Spacing.xl),
        const Icon(
          Icons.celebration_outlined,
          size: 72,
          color: NexoColors.success,
        ),
        const SizedBox(height: Spacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            '¡Listo, $firstName!',
            key: const Key('onboarding_welcome'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        const Text(
          'Tu cuenta de ahorros ya está abierta. Desde ahora puedes ingresar '
          'con tu usuario y contraseña.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.xl),
        PrimaryButton(
          key: const Key('onboarding_start'),
          label: 'Comenzar',
          onPressed: () =>
              context.read<SessionCubit>().authenticated(state.session!),
        ),
      ],
    );
  }
}

/// Enlace del login al registro.
class CreateAccountLink extends StatelessWidget {
  const CreateAccountLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
    key: const Key('login_create_account'),
    onPressed: () => context.push(Routes.register),
    child: const Text('¿No tienes cuenta? Crea una'),
  );
}
