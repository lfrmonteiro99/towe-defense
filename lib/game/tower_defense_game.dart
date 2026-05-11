import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'map.dart';
import 'tower.dart';
import 'enemy.dart';
import 'hud_notifier.dart';

class TowerDefenseGame extends FlameGame with TapCallbacks {
  late GameMap map;
  final List<Enemy> enemies = [];
  final HudNotifier hudNotifier = HudNotifier();

  int selectedTowerType = 0;
  Tower? _selectedTower;

  // Wave spawning state
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

    for (final child in List.of(children)) {
      if (child is Tower || child is Enemy) {
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

    // Check tap on existing tower (anchor=bottomCenter, so center is offset up)
    for (final child in children) {
      if (child is Tower) {
        final towerCenter = child.position - Vector2(0, child.size.y / 2);
        if ((towerCenter - tapPos).length < child.size.x * 0.7) {
          _handleTowerTap(child);
          return;
        }
      }
    }

    // Deselect
    if (_selectedTower != null) {
      _selectedTower!.selected = false;
      _selectedTower = null;
      return;
    }

    // Place new tower
    final tile = map.screenToTile(tapPos);
    if (tile == null) return;
    final (col, row) = tile;
    if (map.isPathTile(col, row)) return;

    final center = map.tileCenter(col, row);
    for (final child in children) {
      if (child is Tower) {
        final towerCenter = child.position - Vector2(0, child.size.y / 2);
        if ((towerCenter - center).length < map.tileSize * 0.8) return;
      }
    }

    final towerType = TowerType.values[selectedTowerType];
    final cost = kTowerData[towerType]!.baseCost;
    if (!hudNotifier.spendGold(cost)) return;

    add(Tower(type: towerType, pos: center));
  }

  void _handleTowerTap(Tower tower) {
    if (_selectedTower == tower) {
      // Second tap: upgrade if possible
      final cost = tower.upgradeCost;
      if (cost != null && hudNotifier.spendGold(cost)) {
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
