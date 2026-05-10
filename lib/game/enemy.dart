import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tower_defense_game.dart';

enum EnemyType { goblin, orc, troll, boss }

class Enemy extends PositionComponent with HasGameRef<TowerDefenseGame> {
  final EnemyType type;
  late double maxHp;
  late double hp;
  late double speed;
  late int reward;
  late Color _color;
  late double _radius;

  int _pathIndex = 0;
  bool _dead = false;
  bool _reachedEnd = false;

  Enemy({required this.type, required int wave}) {
    _initStats(wave);
    anchor = Anchor.center;
  }

  void _initStats(int wave) {
    final scale = 1.0 + (wave - 1) * 0.15;
    switch (type) {
      case EnemyType.goblin:
        maxHp = 60 * scale;
        speed = 80;
        reward = 10;
        _color = Colors.green;
        _radius = 10;
        break;
      case EnemyType.orc:
        maxHp = 150 * scale;
        speed = 50;
        reward = 20;
        _color = Colors.brown;
        _radius = 13;
        break;
      case EnemyType.troll:
        maxHp = 300 * scale;
        speed = 35;
        reward = 35;
        _color = Colors.blueGrey;
        _radius = 16;
        break;
      case EnemyType.boss:
        maxHp = 800 * scale;
        speed = 30;
        reward = 100;
        _color = Colors.deepPurple;
        _radius = 20;
        break;
    }
    hp = maxHp;
  }

  bool get isDead => _dead;
  bool get reachedEnd => _reachedEnd;

  void takeDamage(double dmg) {
    if (_dead) return;
    hp -= dmg;
    if (hp <= 0) _dead = true;
  }

  @override
  Future<void> onLoad() async {
    position = gameRef.map.pathPoints.first.clone();
  }

  @override
  void update(double dt) {
    if (_dead) {
      gameRef.hudNotifier.addGold(reward);
      gameRef.enemies.remove(this);
      removeFromParent();
      return;
    }
    if (_reachedEnd) {
      gameRef.hudNotifier.loseLife();
      gameRef.enemies.remove(this);
      removeFromParent();
      if (gameRef.hudNotifier.lives <= 0) gameRef.triggerGameOver();
      return;
    }

    final pathPoints = gameRef.map.pathPoints;
    if (_pathIndex >= pathPoints.length - 1) {
      _reachedEnd = true;
      return;
    }
    final target = pathPoints[_pathIndex + 1];
    final dir = target - position;
    final dist = dir.length;
    final step = speed * dt;
    if (step >= dist) {
      position = target.clone();
      _pathIndex++;
    } else {
      position += dir.normalized() * step;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(_radius * 0.1, _radius * 0.2),
      _radius,
      Paint()..color = Colors.black38,
    );
    canvas.drawCircle(Offset.zero, _radius, Paint()..color = _color);
    canvas.drawCircle(
      Offset.zero,
      _radius,
      Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final barW = _radius * 2.4;
    final barH = 4.0;
    final barX = -barW / 2;
    final barY = -_radius - 9;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW, barH),
      Paint()..color = Colors.red.shade900,
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW * (hp / maxHp).clamp(0, 1), barH),
      Paint()..color = Colors.greenAccent,
    );
  }
}

List<(EnemyType, int)> buildWave(int waveNumber) {
  final rng = Random(waveNumber * 42);
  final List<(EnemyType, int)> spawn = [];

  final goblins = 5 + waveNumber * 2;
  final orcs = max(0, waveNumber - 2) * 2;
  final trolls = max(0, waveNumber - 5);
  final hasBoss = waveNumber % 5 == 0;

  for (int i = 0; i < goblins; i++) {
    spawn.add((EnemyType.goblin, rng.nextInt(500)));
  }
  for (int i = 0; i < orcs; i++) {
    spawn.add((EnemyType.orc, rng.nextInt(800)));
  }
  for (int i = 0; i < trolls; i++) {
    spawn.add((EnemyType.troll, rng.nextInt(1200)));
  }
  if (hasBoss) {
    spawn.add((EnemyType.boss, 1500));
  }

  spawn.sort((a, b) => a.$2.compareTo(b.$2));
  return spawn;
}
