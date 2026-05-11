import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tower_defense_game.dart';

enum EnemyType { goblin, orc, troll, boss }

const Map<EnemyType, String> _enemySprites = {
  EnemyType.goblin: 'sprites/enemy_goblin.png',
  EnemyType.orc: 'sprites/enemy_orc.png',
  EnemyType.troll: 'sprites/enemy_troll.png',
  EnemyType.boss: 'sprites/enemy_boss.png',
};

class Enemy extends SpriteComponent with HasGameRef<TowerDefenseGame> {
  final EnemyType type;
  late double maxHp;
  late double hp;
  late double speed;
  late int reward;

  int _pathIndex = 0;
  bool _dead = false;
  bool _reachedEnd = false;
  bool _processed = false; // guard against double-processing

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
        break;
      case EnemyType.orc:
        maxHp = 150 * scale;
        speed = 50;
        reward = 20;
        break;
      case EnemyType.troll:
        maxHp = 300 * scale;
        speed = 35;
        reward = 35;
        break;
      case EnemyType.boss:
        maxHp = 800 * scale;
        speed = 30;
        reward = 100;
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

  double get _displayW {
    final ts = gameRef.map.tileSize;
    return switch (type) {
      EnemyType.goblin => ts * 1.2,
      EnemyType.orc    => ts * 1.4,
      EnemyType.troll  => ts * 2.0,
      EnemyType.boss   => ts * 2.4,
    };
  }

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(_enemySprites[type]!);
    final w = _displayW;
    // Maintain sprite aspect ratio: troll is wide (248x108), others are squarish
    final origAspect = switch (type) {
      EnemyType.troll => 248.0 / 108.0,
      EnemyType.boss  => 258.0 / 262.0,
      EnemyType.orc   => 120.0 / 130.0,
      EnemyType.goblin => 115.0 / 115.0,
    };
    size = Vector2(w, w / origAspect);
    position = gameRef.map.pathPoints.first.clone();
  }

  @override
  void update(double dt) {
    if (_processed) return;

    if (_dead) {
      _processed = true;
      gameRef.hudNotifier.addGold(reward);
      gameRef.enemies.remove(this);
      removeFromParent();
      return;
    }
    if (_reachedEnd) {
      _processed = true;
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
    // Sprite
    super.render(canvas);

    // Health bar (above sprite)
    final barW = size.x;
    const barH = 5.0;
    final barX = -barW / 2;
    final barY = -size.y / 2 - 9;
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
