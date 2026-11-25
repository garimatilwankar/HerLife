import 'package:flutter/material.dart';
import '../core/design_tokens.dart';

/// Every tab uses this so header, background and padding are identical.
class HerTabScaffold extends StatelessWidget {
  final Widget header; // HerLifeHeader(...)
  final Widget body;
  const HerTabScaffold({super.key, required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HL.cream,
      body: Column(children: [header, Expanded(child: body)]),
    );
  }
}

/// Standard card: same radius, shadow and padding everywhere.
class HerCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsets padding;

  const HerCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(HL.pad),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(HL.radius),
        onTap: onTap,
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? (color ?? Colors.white) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(HL.radius),
            boxShadow: HL.shadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small tappable pill (filters, symptoms, "Watch", "5 min").
class HerChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const HerChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : HL.wine;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? HL.wine : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? HL.wine : HL.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }
}

class HerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool soft; // tinted version for secondary actions (e.g. "Add end")

  const HerButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: soft ? HL.blush : HL.wine,
        foregroundColor: soft ? HL.wine : Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}

/// Empty state: never a blank screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: HL.blush,
              child: Icon(icon, size: 34, color: HL.wine),
            ),
            const SizedBox(height: 16),
            Text(title, style: HL.section, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: HL.caption, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              HerButton(label: actionLabel!, onPressed: onAction),
            ],
          ]),
        ),
      );
}

/// Error state: a server failure must never look like "no data".
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => HerCard(
        color: const Color(0xFFFFF4E5),
        child: Row(children: [
          const Icon(Icons.cloud_off, color: HL.wine),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: HL.body)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

/// Grey shimmer-style placeholder while loading (simple pulsing, no package).
class SkeletonCard extends StatefulWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 110});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
                const Color(0xFFF0E8E8), const Color(0xFFFBF5F5), _c.value),
            borderRadius: BorderRadius.circular(HL.radius),
          ),
        ),
      );
}

/// Section title row with optional action, used on every tab.
class SectionTitle extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.text, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: HL.section)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: HL.wine, fontWeight: FontWeight.w700)),
            ),
        ]),
      );
}