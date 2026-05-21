import 'package:acai_stock/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AcaiButton extends StatelessWidget {
  const AcaiButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool outlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    return SizedBox(
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: effectiveOnPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  : Text(text),
            )
          : FilledButton(
              onPressed: effectiveOnPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(text),
            ),
    );
  }
}
