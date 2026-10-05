import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Campo de texto del design system. Con [obscure] agrega el botón para
/// mostrar u ocultar el contenido.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final IconData? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _hidden,
      enableSuggestions: !widget.obscure,
      autocorrect: !widget.obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden
                    ? context.l10n.showPassword
                    : context.l10n.hidePassword,
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
