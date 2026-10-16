// Reusable design-system widgets implementing the Stitch Kinetic Precision
// visual language. The whole app builds from these primitives.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/zen_colors.dart';
import '../../core/theme/zen_typography.dart';

class ZenCard extends StatelessWidget {
  const ZenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = ZenRadius.cardLg,
    this.background = ZenSurfaces.card,
    this.border = ZenOutline.hairline,
    this.shadow = ZenShadow.resting,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color background;
  final Color border;
  final List<BoxShadow> shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: border, width: 0.6),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: body,
      ),
    );
  }
}

enum ZenButtonVariant { primary, secondary, ghost, danger }

class ZenButton extends StatelessWidget {
  const ZenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ZenButtonVariant.primary,
    this.icon,
    this.height = 52,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ZenButtonVariant variant;
  final IconData? icon;
  final double height;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    late Color bg;
    late Color fg;
    late BorderSide? borderSide;
    late List<BoxShadow>? shadow;
    switch (variant) {
      case ZenButtonVariant.primary:
        bg = enabled
            ? ZenAccent.primaryContainer
            : ZenSurfaces.containerHighest;
        fg = enabled ? ZenText.onPrimary : ZenText.muted;
        shadow = enabled ? ZenShadow.primary : null;
        break;
      case ZenButtonVariant.secondary:
        bg = ZenSurfaces.tile;
        fg = enabled ? ZenText.primary : ZenText.muted;
        borderSide = const BorderSide(color: ZenOutline.hairline);
        break;
      case ZenButtonVariant.ghost:
        bg = Colors.transparent;
        fg = enabled ? ZenAccent.primary : ZenText.muted;
        break;
      case ZenButtonVariant.danger:
        bg = enabled ? ZenAccent.danger : ZenSurfaces.containerHighest;
        fg = enabled ? ZenText.onPrimary : ZenText.muted;
        break;
    }

    final Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: expand ? 16 : 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (loading) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(ZenText.onPrimary),
              ),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: ZenTypography.labelLg.copyWith(color: fg),
          ),
        ],
      ),
    );

    final Widget tap = Material(
      color: Colors.transparent,
      borderRadius: ZenRadius.cardMd,
      child: InkWell(
        borderRadius: ZenRadius.cardMd,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        child: Container(
          height: height,
          constraints: BoxConstraints(minWidth: expand ? double.infinity : 0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: ZenRadius.cardMd,
            border: borderSide == null ? null : Border.fromBorderSide(borderSide!),
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
    return tap;
  }
}

class ZenStatusChip extends StatelessWidget {
  const ZenStatusChip({
    super.key,
    required this.label,
    this.leadingDotColor,
    this.background,
    this.foreground,
    this.icon,
  });

  final String label;
  final Color? leadingDotColor;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? ZenSurfaces.tile,
        borderRadius: ZenRadius.pill,
        border: const Border.fromBorderSide(
          BorderSide(color: ZenOutline.hairline),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: leadingDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground ?? ZenText.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: ZenTypography.labelSm.copyWith(
              color: foreground ?? ZenText.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class ZenAvatar extends StatelessWidget {
  const ZenAvatar({
    super.key,
    this.imageUrl,
    required this.label,
    this.size = 40,
    this.ringColor,
  });

  final String? imageUrl;
  final String label;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final String initial =
        label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ZenSurfaces.tile,
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: 2),
        boxShadow: ringColor != null
            ? [
                BoxShadow(
                  color: ringColor!.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl!.isEmpty
              ? Container(
                  color: ZenSurfaces.tile,
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: ZenTypography.labelMd.copyWith(
                      color: ZenAccent.primary,
                    ),
                  ),
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: ZenSurfaces.tile,
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: ZenTypography.labelMd.copyWith(
                        color: ZenAccent.primary,
                      ),
                    ),
                  ),
                ),
    );
  }
}

class ZenKeypadCell extends StatelessWidget {
  const ZenKeypadCell({super.key, required this.label, this.onTap, this.icon, this.actionColor});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: ZenRadius.cardMd,
      child: InkWell(
        borderRadius: ZenRadius.cardMd,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: ZenSurfaces.card,
            borderRadius: ZenRadius.cardMd,
            border: const Border.fromBorderSide(
              BorderSide(color: ZenOutline.hairline),
            ),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 22, color: actionColor ?? ZenAccent.primary)
              : Text(label,
                  style: ZenTypography.headlineSm.copyWith(
                    color: actionColor ?? ZenText.primary,
                  )),
        ),
      ),
    );
  }
}

class ZenProgressBar extends StatelessWidget {
  const ZenProgressBar({super.key, required this.value, this.height = 6});
  final double value; // 0..1
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: ZenSurfaces.container,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              color: ZenAccent.primaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class ZenLiveDot extends StatefulWidget {
  const ZenLiveDot({super.key, this.size = 8, this.color = ZenAccent.secondary});
  final double size;
  final Color color;

  @override
  State<ZenLiveDot> createState() => _ZenLiveDotState();
}

class _ZenLiveDotState extends State<ZenLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_ctrl),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ZenErrorView extends StatelessWidget {
  const ZenErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: ZenAccent.error),
          const SizedBox(height: 12),
          Text(title, style: ZenTypography.headlineSm),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              style: ZenTypography.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ZenButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry,
              variant: ZenButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class ZenEmptyView extends StatelessWidget {
  const ZenEmptyView({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String? message;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: ZenText.muted),
          const SizedBox(height: 12),
          Text(title, style: ZenTypography.headlineSm),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              style: ZenTypography.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}