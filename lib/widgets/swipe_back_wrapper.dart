import 'package:flutter/material.dart';

class SwipeBackWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        // Deslizar hacia la derecha regresa a la pantalla anterior
        if (velocity > 280) {
          _handleBack(context);
        }
      },
      child: child,
    );
  }
}