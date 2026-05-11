import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'tower_defense_game.dart';

enum TowerType { archer, mage, thunder, wind }

class TowerData {
  final String name;
  final int baseCost;
  final List<double> damage;
  final List<double> range;
  final List<double> fireRate;
  final List<int> upgradeCost;
  final Color color;
  final String spriteName;

  const TowerData({
    required this.name,
    required this.baseCost,
    required this.damage,
    required this.range,
    required this.fireRate,
    required this.upgradeCost,
    required this.color,
    required this.spriteName,
  });
}

const Map<TowerType, TowerData> kTowerData = {
  TowerType.archer: TowerData(
    name: 'Archer',
    baseCost: 50,
    damage: [15, 25, 40],
    range: [120, 140, 160],
    fireRate: [1.2, 1.5, 2.0],
    upgradeCost: [40, 70],
    color: Color(0xFF4CAF50),
    spriteName: 'sprites/tower_archer.png',
  ),
  TowerType.mage: TowerData(
    name: 'Mage',
    baseCost: 80,
    damage: [30, 55, 90],
    range: [100, 120, 140],
    fireRate: [0.7, 0.9, 1.2],
    upgradeCost: [60, 100],
    color: Color(0xFF9C27B0),
    spriteName: 'sprites/tower_mage.png',
  ),
  TowerType.thunder: TowerData(
    name: 'Thunder',
    baseCost: 120,
    damage: [60, 100, 160],
    range: [130, 150, 175],
    fireRate: [0.5, 0.7, 1.0],
    upgradeCost: [90, 140],
    color: Color(0xFFFFEB3B),
    spriteName: 'sprites/tower_thunder.png',
  ),
  TowerType.wind: TowerData(
    name: 'Wind',
    baseCost: 100,
    damage: [20, 35, 55],
    range: [150, 170, 200],
    fireRate: [2.0, 2.5, 3.0],
    upgradeCost: [75, 120],
    color: Color(0xFF00BCD4),
    spriteName: 'sprites/tower_wind.png',
  ),
};

// Level-up upgrade sprites (shared visual progression)
const List<String> _levelUpgradeSprites = [
  'sprites/tower_lv2.png',
  'sprites/tower_lv3.png',
];

class Tower extends SpriteComponent with HasGameRef<TowerDefenseGame> {
  final TowerType type;
  int level = 0;
  late TowerData data;
  double _fireCooldown = 0;
  bool selected = false;

  Tower({required this.type, required Vector2 pos}) {
    data = kTowerData[type]!;
    position = pos;
    anchor = Anchor.center;
  }

  double get damage => data.damage[level];
  double get range => data.range[level];
  double get fireRate => data.fireRate[level];
  int? get upgradeCost =>
      level < data.upgradeCost.length ? data.upgradeCost[level] : null;
  bool get canUpgrade => level < 2;

  double get _displaySize => (gameRef.map.tileSize * 1.9).clamp(28.0, 80.0);

  @override
  Future<void> onLoad() async {
    await _reloadSprite();
    final ds = _displaySize;
    size = Vector2(ds, ds * 1.35);
    anchor = Anchor.bottomCenter;
  }

  Future<void> _reloadSprite() async {
    final spritePath = level == 0
        ? data.spriteName
        : _levelUpgradeSprites[(level - 1).clamp(0, 1)];
    sprite = await gameRef.loadSprite(spritePath);
  }

  void upgrade() {
    if (!canUpgrade) return;
    level++;
    _reloadSprite();
  }

  @override
  void update(double dt) {
    _fireCooldown -= dt;
    if (_fireCooldown <= 0) {
      final target = _findTarget();
      if (target != null) {
        _shoot(target);
        _fireCooldown = 1.0 / fireRate;
      }
    }
  }

  Enemy? _findTarget() {
    Enemy? best;
    double bestDist = double.infinity;
    for (final enemy in gameRef.enemies) {
      if (enemy.isDead || enemy.reachedEnd) continue;
      final dist = (enemy.position - position).length;
      if (dist <= range && dist < bestDist) {
        bestDist = dist;
        best = enemy;
      }
    }
    return best;
  }

  void _shoot(Enemy target) {
    final projSprite = switch (type) {
      TowerType.archer => 'sprites/proj_arrow.png',
      TowerType.mage => 'sprites/proj_fire.png',
      TowerType.thunder => 'sprites/proj_fire.png',
      TowerType.wind => 'sprites/proj_ice.png',
    };
    gameRef.add(Projectile(
      startPos: position.clone(),
      target: target,
      damage: damage,
      spriteName: projSprite,
      speed: type == TowerType.thunder ? 420 : 280,
    ));
  }

  @override
  void render(Canvas canvas) {
    // Range ring (drawn in world space before sprite)
    if (selected) {
      final dy = size.y / 2; // offset because anchor=bottomCenter
      canvas.drawCircle(
        Offset(0, dy),
        range,
        Paint()
          ..color = data.color.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(0, dy),
        range,
        Paint()
          ..color = data.color.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Sprite (SpriteComponent renders at top-left = (0,0) relative to component)
    super.render(canvas);

    // Level pip stars drawn just below sprite center
    final cx = size.x / 2;
    final cy = size.y - 8;
    for (int i = 0; i <= level; i++) {
      final angle = (i - level / 2.0) * 0.5;
      canvas.drawCircle(
        Offset(cx + sin(angle) * 10, cy),
        3.0,
        Paint()..color = Colors.amber,
      );
    }

    // Selection highlight outline
    if (selected) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = data.color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
