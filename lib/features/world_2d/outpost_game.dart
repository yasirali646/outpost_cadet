import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outpost_cadet/core/theme/oc_assets.dart';
import 'package:outpost_cadet/models/models.dart';

/// Open Mars outpost — tiled ground plane (no stretched sky photo).
class OutpostGame extends FlameGame with KeyboardEvents {
  OutpostGame({
    required this.placements,
    required this.onNearestChanged,
  });

  final List<String?> placements;
  final void Function(WorldBuilding? nearest) onNearestChanged;

  /// Set from Flutter joystick overlay (HUD must not block pointers).
  final externalInput = Vector2.zero();
  final keyboardDelta = Vector2.zero();

  static const mapSize = 900.0;
  static const tileSize = 64.0;

  late final CadetComponent cadet;
  late final CameraComponent cameraComponent;
  final List<WorldBuilding> buildings = [];
  /// Solid footprints the cadet cannot walk through (buildings + rock props).
  final List<SolidBlock> blockers = [];
  WorldBuilding? nearest;
  var _worldReady = false;

  Vector2 get moveInput {
    if (externalInput.length2 > 0.0025) return externalInput.clone();
    return keyboardDelta.clone();
  }

  bool hitsBlocker(Vector2 feet, {double bodyRadius = 11}) {
    for (final b in blockers) {
      if (b.hits(feet, bodyRadius)) return true;
    }
    return false;
  }

  /// Slide along obstacles: try X and Y separately.
  void moveCadet(CadetComponent cadet, Vector2 delta) {
    final pad = 48.0;
    final tryX = Vector2(
      (cadet.position.x + delta.x).clamp(pad, mapSize - pad),
      cadet.position.y,
    );
    if (!hitsBlocker(tryX)) cadet.position.x = tryX.x;

    final tryY = Vector2(
      cadet.position.x,
      (cadet.position.y + delta.y).clamp(pad, mapSize - pad),
    );
    if (!hitsBlocker(tryY)) cadet.position.y = tryY.y;
  }

  static int depthOf(double feetY, {int bias = 0}) =>
      (feetY * 10).round() + bias;

  @override
  Color backgroundColor() => const Color(0xFF1A0F0C);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    Flame.images.prefix = 'assets/';

    final imagePaths = <String>[
      for (final f in OcAssets.worldCadetFacings)
        for (var i = 0; i < OcAssets.worldCadetWalkFrames; i++)
          OcAssets.worldCadetFrame(f, i),
      ...OcAssets.worldBuildingIds.map(OcAssets.worldBuilding),
      ...OcAssets.worldPropIds.map(OcAssets.worldProp),
      OcAssets.worldTile('path'),
      OcAssets.worldTile('regolith'),
      OcAssets.worldTile('rocky'),
      OcAssets.worldTile('pad'),
      OcAssets.worldTile('crater_soil'),
      OcAssets.worldTile('road_pad'),
      OcAssets.worldTile('road_dirt_h'),
      OcAssets.worldTile('road_dirt_v'),
      OcAssets.worldTile('road_dirt_corner'),
      OcAssets.worldTile('road_dirt_cross'),
      OcAssets.worldTile('road_transition'),
    ].map((p) => p.replaceFirst('assets/', '')).toList();

    await Flame.images.loadAll(imagePaths);
    await images.loadAll(imagePaths);

    final world = World();
    cameraComponent = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.center
      ..viewfinder.zoom = 1.05;
    await addAll([world, cameraComponent]);

    await world.add(MarsGround(mapSize: mapSize));

    final layout = _homesteadLayout(placements);
    final habitatHub =
        layout['habitat']?.$1 ?? Vector2(mapSize / 2, mapSize / 2);
    final hubs = <Vector2>[
      habitatHub,
      for (final e in layout.entries)
        if (e.key != 'habitat') e.value.$1,
    ];
    await world.add(MixPath(mapSize: mapSize, hubs: hubs));
    await world.add(PropScatter(mapSize: mapSize, game: this));

    for (final entry in layout.entries) {
      final b = WorldBuilding(
        moduleId: entry.key,
        cellIndex: entry.value.$2,
        position: entry.value.$1,
      );
      buildings.add(b);
      await world.add(b);
      blockers.add(b.block);
    }

    final habitatPos =
        layout['habitat']?.$1 ?? Vector2(mapSize / 2, mapSize / 2);
    // Spawn on the ground just south of habitat (feet = bottomCenter).
    cadet = CadetComponent(position: habitatPos + Vector2(0, 110));
    await world.add(cadet);
    // If spawn overlaps a footprint, nudge south until clear.
    for (var i = 0; i < 8 && hitsBlocker(cadet.position); i++) {
      cadet.position.y += 16;
    }
    cameraComponent.follow(cadet);
    _worldReady = true;
  }

  Map<String, (Vector2, int)> _homesteadLayout(List<String?> placements) {
    final center = Vector2(mapSize / 2, mapSize / 2);
    final slots = <Vector2>[
      center + Vector2(-180, -40),
      center + Vector2(180, -40),
      center + Vector2(-120, 140),
      center + Vector2(120, 140),
      center + Vector2(0, -160),
      center + Vector2(-200, 120),
      center + Vector2(200, 120),
      center + Vector2(0, 200),
    ];
    final out = <String, (Vector2, int)>{
      'habitat': (center, OutpostGrid.habitatCell),
    };
    var slot = 0;
    for (var i = 0; i < placements.length; i++) {
      final id = placements[i];
      if (id == null || id == 'habitat') continue;
      final key = out.containsKey(id) ? '${id}_$i' : id;
      out[key] = (slots[slot % slots.length], i);
      slot++;
    }
    return out;
  }

  void refreshNearest() {
    WorldBuilding? best;
    var bestDist = 110.0;
    for (final b in buildings) {
      final d = cadet.position.distanceTo(b.position);
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    if (best != nearest) {
      nearest = best;
      onNearestChanged(best);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_worldReady) refreshNearest();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    keyboardDelta.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      keyboardDelta.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      keyboardDelta.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      keyboardDelta.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      keyboardDelta.x += 1;
    }
    return KeyEventResult.handled;
  }
}

/// Walkable Mars soil — one component (no hundreds of tile children; keeps FPS up).
class MarsGround extends PositionComponent {
  MarsGround({required this.mapSize});

  final double mapSize;
  final _cells = <(Sprite, Vector2)>[];
  late final Paint _basePaint;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(mapSize);
    _basePaint = Paint()..color = const Color(0xFF4A2A1C);
    final regolith = await Sprite.load(
      OcAssets.worldTile('regolith').replaceFirst('assets/', ''),
    );
    final rocky = await Sprite.load(
      OcAssets.worldTile('rocky').replaceFirst('assets/', ''),
    );
    final crater = await Sprite.load(
      OcAssets.worldTile('crater_soil').replaceFirst('assets/', ''),
    );

    const t = OutpostGame.tileSize;
    final n = (mapSize / t).ceil();
    final rng = math.Random(11);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final roll = rng.nextDouble();
        final sprite = roll < 0.12
            ? crater
            : roll < 0.28
                ? rocky
                : regolith;
        _cells.add((sprite, Vector2(x * t, y * t)));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _basePaint);
    // Heavy overlap hides any leftover seams between tiles.
    const t = OutpostGame.tileSize + 6;
    final tileSize = Vector2.all(t);
    for (final cell in _cells) {
      cell.$1.render(
        canvas,
        position: cell.$2 - Vector2(3, 3),
        size: tileSize,
      );
    }
  }
}

/// Elliptical ground footprint used for walk collision (matches wide building bases).
class SolidBlock {
  SolidBlock({
    required this.center,
    required this.halfW,
    required this.halfH,
  });

  Vector2 center;
  double halfW;
  double halfH;

  bool hits(Vector2 feet, double bodyRadius) {
    final dx = (feet.x - center.x) / (halfW + bodyRadius);
    final dy = (feet.y - center.y) / (halfH + bodyRadius);
    return dx * dx + dy * dy < 1.0;
  }
}

/// Option C Mix Path: NASA pads under modules + flat packed-dirt walkways (not pipes).
class MixPath extends PositionComponent {
  MixPath({required this.mapSize, required this.hubs});

  final double mapSize;
  final List<Vector2> hubs;

  @override
  Future<void> onLoad() async {
    final pad = await Sprite.load(
      OcAssets.worldTile('road_pad').replaceFirst('assets/', ''),
    );

    if (hubs.isEmpty) return;
    final center = hubs.first;

    // Flat L-walkways first (under pads).
    for (var i = 1; i < hubs.length; i++) {
      final end = hubs[i];
      final mid = Vector2(end.x, center.y);
      await add(FlatDirtWalk(from: center, to: mid));
      await add(FlatDirtWalk(from: mid, to: end));
    }

    // Pads under modules.
    for (final hub in hubs) {
      await add(
        SpriteComponent(
          sprite: pad,
          size: Vector2(120, 120),
          anchor: Anchor.center,
          position: hub.clone(),
          priority: 3,
        ),
      );
    }
  }
}

/// Flat packed-dirt walkway on the ground — reads as a path, not a pipe.
class FlatDirtWalk extends PositionComponent {
  FlatDirtWalk({required this.from, required this.to}) : super(priority: 2);

  final Vector2 from;
  final Vector2 to;

  static const halfWidth = 16.0;

  @override
  void render(Canvas canvas) {
    final delta = to - from;
    final len = delta.length;
    if (len < 1) return;
    final angle = math.atan2(delta.y, delta.x);

    canvas.save();
    canvas.translate(from.x, from.y);
    canvas.rotate(angle);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -halfWidth, len, halfWidth * 2),
      const Radius.circular(10),
    );
    // Outer soft edge (slightly darker)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-2, -halfWidth - 3, len + 4, halfWidth * 2 + 6),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x665A3018),
    );
    // Packed dirt fill — lighter than deep regolith so it reads as a trail
    canvas.drawRRect(body, Paint()..color = const Color(0xFF9A5C38));
    // Center wear stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -halfWidth * 0.35, len, halfWidth * 0.7),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xCCB87548),
    );
    // Thin edge ruts
    final rut = Paint()
      ..color = const Color(0x667A4028)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(4, -halfWidth + 3), Offset(len - 4, -halfWidth + 3), rut);
    canvas.drawLine(Offset(4, halfWidth - 3), Offset(len - 4, halfWidth - 3), rut);

    canvas.restore();
  }
}

class PropScatter extends PositionComponent {
  PropScatter({required this.mapSize, required this.game});

  final double mapSize;
  final OutpostGame game;

  static const _solid = {'rocks', 'crater', 'rover', 'crate', 'beacon'};

  @override
  Future<void> onLoad() async {
    final rng = math.Random(7);
    const props = ['rocks', 'scrub', 'crater', 'beacon', 'cone', 'rover', 'crate'];
    final center = Vector2(mapSize / 2, mapSize / 2);
    for (var i = 0; i < 12; i++) {
      final id = props[i % props.length];
      final sprite = await Sprite.load(
        OcAssets.worldProp(id).replaceFirst('assets/', ''),
      );
      Vector2 pos;
      do {
        pos = Vector2(
          80 + rng.nextDouble() * (mapSize - 160),
          80 + rng.nextDouble() * (mapSize - 160),
        );
      } while (pos.distanceTo(center) < 150);

      final size = id == 'rover' ? 70.0 : 52.0;
      final prop = WorldProp(
        propId: id,
        sprite: sprite,
        position: pos,
        size: Vector2.all(size),
      );
      await add(prop);
      if (_solid.contains(id)) {
        game.blockers.add(prop.block);
      }
    }
  }
}

class WorldProp extends SpriteComponent {
  WorldProp({
    required this.propId,
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : block = SolidBlock(
          center: position.clone(),
          halfW: size.x * (propId == 'rover' ? 0.34 : 0.30),
          halfH: size.x * 0.22,
        ),
        super(
          sprite: sprite,
          position: position,
          size: size,
          anchor: Anchor.bottomCenter,
          priority: OutpostGame.depthOf(position.y),
        );

  final String propId;
  final SolidBlock block;
}

class WorldBuilding extends SpriteComponent {
  WorldBuilding({
    required this.moduleId,
    required this.cellIndex,
    required Vector2 position,
  })  : block = SolidBlock(
          // Wide ellipse under the dome so cadet cannot walk into the sprite sides.
          center: position + Vector2(0, -8),
          halfW: moduleId.startsWith('habitat') ? 58 : 44,
          halfH: moduleId.startsWith('habitat') ? 32 : 26,
        ),
        super(
          position: position,
          size: Vector2.all(moduleId.startsWith('habitat') ? 140 : 120),
          anchor: Anchor.bottomCenter,
          priority: OutpostGame.depthOf(position.y),
        );

  final String moduleId;
  final int cellIndex;
  final SolidBlock block;

  bool get isHabitat => moduleId == 'habitat' || moduleId.startsWith('habitat');

  String get label {
    final base = moduleId.split('_').first;
    return base.toUpperCase();
  }

  @override
  Future<void> onLoad() async {
    final base = moduleId.split('_').first;
    sprite = await Sprite.load(
      OcAssets.worldBuildingForModule(base).replaceFirst('assets/', ''),
    );
  }
}

class CadetComponent extends SpriteComponent {
  CadetComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(64, 64),
          anchor: Anchor.bottomCenter,
          // +1 bias: at same feet-Y as a building, draw cadet in front (beside door).
          priority: OutpostGame.depthOf(position.y, bias: 1),
        );

  static const speed = 95.0;
  static const walkFps = 7.0;

  String _facing = 'down';
  var _frame = 0;
  var _animT = 0.0;
  final _sprites = <String, List<Sprite>>{};

  void _syncDepth() {
    priority = OutpostGame.depthOf(position.y, bias: 1);
  }

  @override
  Future<void> onLoad() async {
    await add(
      CircleComponent(
        radius: 15,
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y - 1),
        paint: Paint()..color = const Color(0xA0180C08),
        priority: -1,
      )..scale = Vector2(1.4, 0.4),
    );

    for (final f in OcAssets.worldCadetFacings) {
      final frames = <Sprite>[];
      for (var i = 0; i < OcAssets.worldCadetWalkFrames; i++) {
        frames.add(
          await Sprite.load(
            OcAssets.worldCadetFrame(f, i).replaceFirst('assets/', ''),
          ),
        );
      }
      _sprites[f] = frames;
    }
    sprite = _sprites['down']![0];
  }

  @override
  void update(double dt) {
    super.update(dt);
    final game = findGame();
    if (game is! OutpostGame) return;

    final raw = game.moveInput;
    final moving = raw.length2 >= 0.0025;

    if (!moving) {
      _frame = 0;
      _animT = 0;
      sprite = _sprites[_facing]?[0] ?? sprite;
      _syncDepth();
      return;
    }

    final input = raw.normalized();
    game.moveCadet(this, input * speed * dt);
    _syncDepth();

    if (input.x.abs() > input.y.abs()) {
      _facing = input.x < 0 ? 'left' : 'right';
    } else {
      _facing = input.y < 0 ? 'up' : 'down';
    }

    _animT += dt;
    final step = 1.0 / walkFps;
    while (_animT >= step) {
      _animT -= step;
      _frame = (_frame + 1) % OcAssets.worldCadetWalkFrames;
    }
    final frames = _sprites[_facing];
    if (frames != null && frames.isNotEmpty) {
      sprite = frames[_frame];
    }
  }
}
