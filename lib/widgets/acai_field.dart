import 'package:flutter/material.dart';

class AcaiField extends StatelessWidget {
  const AcaiField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.onChanged,
    this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
