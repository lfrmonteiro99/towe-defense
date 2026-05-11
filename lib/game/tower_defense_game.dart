import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'map.dart';
import 'tower.dart';
import 'enemy.dart';
import 'projectile.dart';
import 'hud_notifier.dart';

class TowerDefenseGame extends FlameGame with TapCallbacks {
  late GameMap map;
  final List<Enemy> enemies = [];
  final HudNotifier hudNotifier = HudNotifier();

  int selectedTowerType = 0;
  Tower? _selectedTower;

  List<(EnemyType, int)> _waveSpawnList = [];
  double _waveTimerMs = 0;
  int _spawnIndex = 0;
  bool _spawning = false;

  static const int maxWaves = 10;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    map = GameMap();
    await add(map);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_spawning) {
      _waveTimerMs += dt * 1000;
      while (_spawnIndex < _waveSpawnList.length &&
          _waveTimerMs >= _waveSpawnList[_spawnIndex].$2) {
        _spawnEnemy(_waveSpawnList[_spawnIndex].$1);
        _spawnIndex++;
      }
      if (_spawnIndex >= _waveSpawnList.length) _spawning = false;
    }

    if (!_spawning && hudNotifier.waveInProgress && enemies.isEmpty) {
      _onWaveComplete();
    }
  }

  void _spawnEnemy(EnemyType type) {
    final enemy = Enemy(type: type, wave: hudNotifier.wave);
    enemies.add(enemy);
    add(enemy);
  }

  void startNextWave() {
    if (hudNotifier.waveInProgress || hudNotifier.wave >= maxWaves) return;
    hudNotifier.setWave(hudNotifier.wave + 1);
    hudNotifier.setWaveInProgress(true);
    _waveSpawnList = buildWave(hudNotifier.wave);
    _waveTimerMs = 0;
    _spawnIndex = 0;
    _spawning = true;
  }

  void _onWaveComplete() {
    hudNotifier.setWaveInProgress(false);
    hudNotifier.addGold(20 + hudNotifier.wave * 5);
    if (hudNotifier.wave >= maxWaves) {
      overlays.add('victory');
    }
  }

  void triggerGameOver() {
    overlays.add('game_over');
    pauseEngine();
  }

  void restartGame() {
    overlays.remove('game_over');
    overlays.remove('victory');
    hudNotifier.reset();

    // Remove all game-object components (towers, enemies, and in-flight projectiles).
    for (final child in List.of(children)) {
      if (child is Tower || child is Enemy || child is Projectile) {
        child.removeFromParent();
      }
    }
    enemies.clear();
    _spawning = false;
    _spawnIndex = 0;
    _selectedTower = null;

    resumeEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPos = event.localPosition;

    // Check tap on an existing tower.
    // Tower.position = bottom-center (anchor=bottomCenter); visual centre is offset up by size.y/2.
    for (final child in children) {
      if (child is Tower) {
        final visualCenter = child.position - Vector2(0, child.size.y / 2);
        if ((visualCenter - tapPos).length < child.size.x * 0.7) {
          _handleTowerTap(child);
          return;
        }
      }
    }

    // Tap elsewhere while a tower is selected → deselect.
    if (_selectedTower != null) {
      _selectedTower!.selected = false;
      _selectedTower = null;
      return;
    }

    // Place a new tower.
    final tile = map.screenToTile(tapPos);
    if (tile == null) return;
    final (col, row) = tile;
    if (map.isPathTile(col, row)) return;

    // Reject if a tower is already placed on this tile.
    // child.position IS the placement point (bottomCenter anchor = bottom of tile).
    final placementPt = map.tilePlacementPoint(col, row);
    for (final child in children) {
      if (child is Tower &&
          (child.position - placementPt).length < map.tileSize * 0.8) return;
    }

    final towerType = TowerType.values[selectedTowerType];
    final cost = kTowerData[towerType]!.baseCost;
    if (!hudNotifier.spendGold(cost)) return;

    add(Tower(type: towerType, pos: placementPt));
  }

  void _handleTowerTap(Tower tower) {
    if (_selectedTower == tower) {
      // Second tap on the same tower → upgrade.
      final cost = tower.upgradeCost;
      if (cost != null && hudNotifier.spendGold(cost)) {
        // upgrade() is async (sprite reload); result is intentionally not awaited here
        // because game state (level, damage) updates synchronously and the sprite
        // swap completes on the next frame from the image cache.
        tower.upgrade();
      }
      tower.selected = false;
      _selectedTower = null;
    } else {
      _selectedTower?.selected = false;
      tower.selected = true;
      _selectedTower = tower;
    }
  }
}
