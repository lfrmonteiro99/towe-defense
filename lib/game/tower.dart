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
  final String icon;

  const TowerData({
    required this.name,
    required this.baseCost,
    required this.damage,
    required this.range,
    required this.fireRate,
    required this.upgradeCost,
    required this.color,
    required this.icon,
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
    icon: '🏹',
  ),
  TowerType.mage: TowerData(
    name: 'Mage',
    baseCost: 80,
    damage: [30, 55, 90],
    range: [100, 120, 140],
    fireRate: [0.7, 0.9, 1.2],
    upgradeCost: [60, 100],
    color: Color(0xFF9C27B0),
    icon: '🔮',
  ),
  TowerType.thunder: TowerData(
    name: 'Thunder',
    baseCost: 120,
    damage: [60, 100, 160],
    range: [130, 150, 175],
    fireRate: [0.5, 0.7, 1.0],
    upgradeCost: [90, 140],
    color: Color(0xFFFFEB3B),
    icon: '⚡',
  ),
  TowerType.wind: TowerData(
    name: 'Wind',
    baseCost: 100,
    damage: [20, 35, 55],
    range: [150, 170, 200],
    fireRate: [2.0, 2.5, 3.0],
    upgradeCost: [75, 120],
    color: Color(0xFF00BCD4),
    icon: '🌀',
  ),
};

class Tower extends PositionComponent with HasGameRef<TowerDefenseGame> {
  final TowerType type;
  int level = 0;
  late TowerData data;
  double _fireCooldown = 0;
  bool selected = false;

  Tower({required this.type, required Vector2 pos}) {
    data = kTowerData[type]!;
    position = pos;
    anchor = Anchor.center;
    size = Vector2.all(36);
  }

  double get damage => data.damage[level];
  double get range => data.range[level];
  double get fireRate => data.fireRate[level];
  int? get upgradeCost =>
      level < data.upgradeCost.length ? data.upgradeCost[level] : null;
  bool get canUpgrade => level < 2;

  void upgrade() {
    if (canUpgrade) level++;
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
    final projColor = switch (type) {
      TowerType.archer => const Color(0xFF8D6E63),
      TowerType.mage => Colors.purple,
      TowerType.thunder => Colors.yellow,
      TowerType.wind => Colors.cyan,
    };
    gameRef.add(Projectile(
      startPos: position.clone(),
      target: target,
      damage: damage,
      color: projColor,
      speed: type == TowerType.thunder ? 400 : 270,
      radius: type == TowerType.thunder ? 7 : 5,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (selected) {
      canvas.drawCircle(
        Offset.zero,
        range,
        Paint()
          ..color = data.color.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset.zero,
        range,
        Paint()
          ..color = data.color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(Offset.zero, 17, Paint()..color = Colors.grey.shade800);
    canvas.drawCircle(
        Offset.zero, 15, Paint()..color = data.color.withOpacity(0.85));
    canvas.drawCircle(
      Offset.zero,
      15,
      Paint()
        ..color = selected ? Colors.white : Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1,
    );

    for (int i = 0; i <= level; i++) {
      final angle = (i - level / 2.0) * 0.45;
      canvas.drawCircle(
        Offset(sin(angle) * 10, -cos(angle) * 10),
        2.5,
        Paint()..color = Colors.amber,
      );
    }

    final tp = TextPainter(
      text: TextSpan(text: data.icon, style: const TextStyle(fontSize: 15)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
