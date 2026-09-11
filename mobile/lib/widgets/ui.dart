import 'package:flutter/material.dart';

import '../theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = C.surface,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border),
        boxShadow: kCardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

class StatusChip extends StatelessWidget {
  final String raw;
  final String? label;
  const StatusChip(this.raw, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(raw);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label ?? statusLabel(raw),
          style: T.sans(10.5, weight: FontWeight.w600, color: s.fg)),
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: C.paper, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? C.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active ? kCardShadow : null,
                ),
                child: Text(labels[i],
                    style: T.sans(12.5,
                        weight: FontWeight.w700,
                        color: active ? C.deepTeal : C.muted)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: T.sans(15, weight: FontWeight.w700)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color color;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.color = C.teal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: T.sans(14,
                          weight: FontWeight.w700, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

class OutlineButton2 extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  const OutlineButton2({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = C.ink,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label,
              style: T.sans(13, weight: FontWeight.w700, color: color)),
        ),
      );
}

class StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const StatCell(this.label, this.value, {super.key, this.valueColor = C.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: C.paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: T.mono(16, color: valueColor)),
          const SizedBox(height: 4),
          Text(label,
              style: T.sans(11, color: C.muted, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
            child: CircularProgressIndicator(color: C.teal, strokeWidth: 2.6)),
      );
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: C.muted, size: 32),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: T.sans(12.5, color: C.muted, height: 1.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton(
                  onPressed: onRetry,
                  child: Text('Coba lagi',
                      style:
                          T.sans(13, weight: FontWeight.w700, color: C.teal))),
            ],
          ],
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_rounded});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, color: C.muted.withValues(alpha: 0.6), size: 30),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: T.sans(12.5, color: C.muted)),
          ],
        ),
      );
}

void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? C.coral : C.ink,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Row(children: [
      Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: error ? Colors.white : C.mint, size: 18),
      const SizedBox(width: 10),
      Expanded(
          child: Text(message,
              style:
                  T.sans(12.5, weight: FontWeight.w500, color: Colors.white))),
    ]),
  ));
}
