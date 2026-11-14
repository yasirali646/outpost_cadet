import 'package:flutter/material.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/core/widgets/oc_chrome.dart';
import 'package:outpost_cadet/core/widgets/oc_motion.dart';
import 'package:outpost_cadet/models/models.dart';

class ResourceMetersBar extends StatelessWidget {
  const ResourceMetersBar({super.key, required this.meters});

  final ResourceMeters meters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MeterRow(
          label: 'Life',
          asset: OcAssets.life,
          value: meters.lifeSupport,
          max: meters.lifeCap,
          color: OcTokens.life,
          warn: meters.lifeCritical,
        ),
        _MeterRow(
          label: 'Shield',
          asset: OcAssets.shieldRes,
          value: meters.radiationCap - meters.radiation,
          max: meters.radiationCap,
          color: OcTokens.shield,
          warn: meters.radiationCritical,
        ),
        _MeterRow(
          label: 'Power',
          asset: OcAssets.power,
          value: meters.power,
          max: meters.powerCap,
          color: OcTokens.power,
          warn: meters.powerCritical,
        ),
        _MeterRow(
          label: 'Food',
          asset: OcAssets.food,
          value: meters.food,
          max: meters.foodCap,
          color: OcTokens.food,
          warn: meters.foodCritical,
        ),
      ],
    );
  }
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({
    required this.label,
    required this.asset,
    required this.value,
    required this.max,
    required this.color,
    required this.warn,
  });

  final String label;
  final String asset;
  final double value;
  final double max;
  final Color color;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final t = (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          OcAssetIcon(asset, size: 22),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: warn ? OcTokens.danger : OcTokens.bone,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: OcAnimatedMeter(
              value: t,
              color: warn ? OcTokens.danger : color,
              minHeight: 10,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: OcTokens.sand,
                fontSize: 12,
                fontWeight: warn ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData iconForModule(String key) {
  return switch (key) {
    'home' => Icons.home_rounded,
    'wb_sunny' => Icons.wb_sunny_rounded,
    'battery_charging_full' => Icons.battery_charging_full_rounded,
    'water_drop' => Icons.water_drop_rounded,
    'yard' => Icons.yard_rounded,
    'shield' => Icons.shield_rounded,
    'science' => Icons.science_rounded,
    'build' => Icons.build_rounded,
    _ => Icons.widgets_rounded,
  };
}

Widget moduleArt(String moduleId, {double size = 36}) {
  return OcAssetIcon(OcAssets.module(moduleId), size: size);
}

class MarsScaffold extends StatelessWidget {
  const MarsScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      floatingActionButton: floatingActionButton,
      body: MarsBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              OcPageHeader(
                title: title.toUpperCase(),
                subtitle: subtitle ?? '',
                trailing: actions == null
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ),
              Expanded(child: child),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}
