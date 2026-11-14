import 'package:flutter/material.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';

class MarsBackdrop extends StatelessWidget {
  const MarsBackdrop({
    super.key,
    required this.child,
    this.dim = 0.45,
    this.imageAsset = OcAssets.marsBg,
  });

  final Widget child;
  final double dim;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: OcTokens.spaceBlack),
        ),
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OcTokens.spaceBlack.withValues(alpha: 0.78),
                  OcTokens.spaceBlack.withValues(alpha: dim * 0.4),
                  OcTokens.spaceBlack.withValues(alpha: 0.92),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class OcPanel extends StatelessWidget {
  const OcPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: OcTokens.panelSolid.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(OcTokens.radiusMd),
        border: Border.all(
          color: highlighted
              ? OcTokens.rust
              : (borderColor ?? OcTokens.panelBorder),
          width: highlighted ? 1.6 : 1,
        ),
      ),
      child: child,
    );
  }
}

class OcSectionLabel extends StatelessWidget {
  const OcSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: OcTokens.bodyFamily,
        color: color ?? OcTokens.rust,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        fontSize: 12,
      ),
    );
  }
}

class OcAssetIcon extends StatelessWidget {
  const OcAssetIcon(
    this.path, {
    super.key,
    this.size = 28,
  });

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Shared orange-border back control (Build / Run / Debrief).
class OcBackButton extends StatelessWidget {
  const OcBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OcTokens.rust, width: 1.5),
          color: OcTokens.panelSolid.withValues(alpha: 0.75),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_rounded,
          color: OcTokens.bone,
          size: 22,
        ),
      ),
    );
  }
}

/// Shell / page title strip matching Training Command headers.
class OcPageHeader extends StatelessWidget {
  const OcPageHeader({
    super.key,
    required this.subtitle,
    this.title = 'OUTPOST CADET',
    this.trailing,
    this.leading,
    this.centered = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final titles = Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!centered) ...[
              OcAssetIcon(OcAssets.shieldStar, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: OcTokens.displayFamily,
                  color: OcTokens.bone,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (subtitle.trim().isNotEmpty)
          Text(
            subtitle.startsWith('--') ? subtitle : '-- $subtitle --',
            style: const TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: OcTokens.rust,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(child: titles),
          ?trailing,
        ],
      ),
    );
  }
}


class OcPrimaryCta extends StatelessWidget {
  const OcPrimaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.sublabel,
    this.iconAsset = OcAssets.rocket,
    this.icon,
    this.boneStyle = false,
  });

  final String label;
  final String? sublabel;
  final VoidCallback? onPressed;
  final String iconAsset;
  final IconData? icon;
  final bool boneStyle;

  @override
  Widget build(BuildContext context) {
    final bg = boneStyle ? OcTokens.bone : OcTokens.rust;
    final titleColor = boneStyle ? OcTokens.spaceBlack : Colors.white;
    final subColor = boneStyle
        ? OcTokens.spaceBlack.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.7);
    final iconColor = boneStyle ? OcTokens.rust : Colors.white;
    final resolvedIcon = icon ??
        (boneStyle ? Icons.rocket_launch_rounded : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(OcTokens.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(OcTokens.radiusSm),
            boxShadow: boneStyle
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : OcTokens.softGlow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              children: [
                if (resolvedIcon != null)
                  Icon(resolvedIcon, size: 30, color: iconColor)
                else
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    child: OcAssetIcon(iconAsset, size: 30),
                  ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: OcTokens.bodyFamily,
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (sublabel != null)
                        Text(
                          sublabel!,
                          style: TextStyle(
                            fontFamily: OcTokens.bodyFamily,
                            color: subColor,
                            fontSize: 12,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OcBrandTitle extends StatelessWidget {
  const OcBrandTitle({
    super.key,
    this.subtitle = 'JUNIOR MISSION CONTROL',
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'OUTPOST',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: OcTokens.displayFamily,
            fontSize: 56,
            letterSpacing: 4,
            height: 0.92,
            color: OcTokens.bone,
          ),
        ),
        Text(
          'CADET',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: OcTokens.displayFamily,
            fontSize: 56,
            letterSpacing: 4,
            height: 0.92,
            color: OcTokens.bone,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _WingLine(alignEnd: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: OcTokens.bodyFamily,
                  color: OcTokens.bone,
                  fontSize: 11,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: _WingLine(alignEnd: false)),
          ],
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.auto_awesome,
          size: 14,
          color: OcTokens.bone.withValues(alpha: 0.9),
        ),
      ],
    );
  }
}

/// Decorative flank lines: long inner segment + short outer tip (wing / rank bars).
class _WingLine extends StatelessWidget {
  const _WingLine({required this.alignEnd});

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final long = Container(
      height: 1.2,
      color: OcTokens.bone.withValues(alpha: 0.75),
    );
    final short = Container(
      width: 14,
      height: 1.2,
      color: OcTokens.bone.withValues(alpha: 0.75),
    );
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [
              short,
              const SizedBox(width: 5),
              Flexible(child: long),
            ]
          : [
              Flexible(child: long),
              const SizedBox(width: 5),
              short,
            ],
    );
  }
}
