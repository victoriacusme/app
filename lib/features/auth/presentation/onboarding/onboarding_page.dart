import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/session_cubit.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/domain_l10n.dart';
import '../../../../l10n/l10n.dart';
import 'onboarding_cubit.dart';

/// Registro en pasos con barra de progreso.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static String _title(AppLocalizations l10n, OnboardingStep step) =>
      switch (step) {
        OnboardingStep.personal => l10n.onboardingStepPersonal,
        OnboardingStep.credentials => l10n.onboardingStepCredentials,
        OnboardingStep.terms => l10n.onboardingStepTerms,
        OnboardingStep.welcome => l10n.onboardingStepWelcome,
      };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final state = context.watch<OnboardingCubit>().state;
    final l10n = context.l10n;
    final step = state.step;
    final total = OnboardingStep.values.length;
    return PopScope(
      canPop: step == OnboardingStep.personal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) cubit.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(l10n, step)),
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
                label: l10n.onboardingStepOf(step.index + 1, total),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: state.progress,
                        borderRadius: const BorderRadius.all(Radii.sm),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text('${step.index + 1}/$total'),
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
  const _StepLayout({required this.children, this.buttonLabel});

  final List<Widget> children;

  /// Por defecto, "Continuar".
  final String? buttonLabel;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final l10n = context.l10n;
    // El botón queda fijo abajo, fuera del scroll: siempre visible aunque el
    // formulario sea largo o el teclado achique la pantalla.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              if (state.failure != null) ...[
                InlineMessage(
                  key: const Key('onboarding_error'),
                  message: state.failure!.localized(l10n),
                ),
                const SizedBox(height: Spacing.md),
              ],
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: PrimaryButton(
            key: const Key('onboarding_next'),
            label: buttonLabel ?? l10n.continueAction,
            loading: state.submitting,
            onPressed: () {
              FocusScope.of(context).unfocus();
              context.read<OnboardingCubit>().next();
            },
          ),
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

  /// Al salir del campo se valida lo que se escribió.
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        context.read<OnboardingCubit>().fieldLeft(widget.field);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = context.select(
      (OnboardingCubit c) => c.state.visibleError(widget.field),
    );
    final enabled = !context.select((OnboardingCubit c) => c.state.submitting);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: TextField(
        key: Key('onboarding_${widget.field.name}'),
        controller: _controller,
        focusNode: _focus,
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
          errorText: error?.message(l10n),
          errorMaxLines: 2,
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? l10n.showPassword : l10n.hidePassword,
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
    final l10n = context.l10n;
    final birthDate = state.birthDate;
    final birthError = state.visibleError(OnboardingField.birthDate);
    return _StepLayout(
      children: [
        _Field(
          OnboardingField.fullName,
          label: l10n.fullNameLabel,
          keyboardType: TextInputType.name,
          autofillHints: const [AutofillHints.name],
        ),
        _Field(
          OnboardingField.idNumber,
          label: l10n.idNumberLabel,
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
                labelText: l10n.birthDateLabel,
                errorText: birthError?.message(l10n),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(birthDate == null ? '' : l10n.shortDate(birthDate)),
            ),
          ),
        ),
        _Field(
          OnboardingField.email,
          label: l10n.emailLabel,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        _Field(
          OnboardingField.phone,
          label: l10n.phoneLabel,
          helperText: l10n.phoneHelper,
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
      helpText: context.l10n.birthDateLabel,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) cubit.birthDateChanged(picked);
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AutofillGroup(
      child: _StepLayout(
        children: [
          _Field(
            OnboardingField.username,
            label: l10n.usernameLabel,
            helperText: l10n.usernameHelper,
            autofillHints: const [AutofillHints.newUsername],
          ),
          _Field(
            OnboardingField.password,
            label: l10n.passwordLabel,
            helperText: l10n.passwordHelper,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
          _Field(
            OnboardingField.confirmation,
            label: l10n.confirmPasswordLabel,
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
    final l10n = context.l10n;
    final error = state.visibleError(OnboardingField.terms);
    return _StepLayout(
      buttonLabel: l10n.createMyAccount,
      children: [
        Text(l10n.termsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(l10n.termsBody),
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
          title: Text(l10n.termsAccept),
          subtitle: error == null
              ? null
              : Text(
                  error.message(l10n),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
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
    final l10n = context.l10n;
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
            l10n.welcomeTitle(firstName),
            key: const Key('onboarding_welcome'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(l10n.welcomeBody, textAlign: TextAlign.center),
        const SizedBox(height: Spacing.xl),
        PrimaryButton(
          key: const Key('onboarding_start'),
          label: l10n.start,
          onPressed: () => unawaited(
            context.read<SessionCubit>().authenticated(state.session!),
          ),
        ),
      ],
    );
  }
}
