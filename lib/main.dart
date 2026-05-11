import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/tower_defense_game.dart';
import 'game/tower.dart';
// ignore: unused_import (used via Image.asset in the menu)

void main() {
  runApp(const TowerDefenseApp());
}

class TowerDefenseApp extends StatelessWidget {
  const TowerDefenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tower Defense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TowerDefenseGame _game;

  @override
  void initState() {
    super.initState();
    _game = TowerDefenseGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, game) =>
              HudOverlay(game: game as TowerDefenseGame),
          'tower_menu': (context, game) =>
              TowerMenuOverlay(game: game as TowerDefenseGame),
          'game_over': (context, game) =>
              GameOverOverlay(game: game as TowerDefenseGame),
          'victory': (context, game) =>
              VictoryOverlay(game: game as TowerDefenseGame),
        },
        initialActiveOverlays: const ['hud', 'tower_menu'],
      ),
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class HudOverlay extends StatelessWidget {
  final TowerDefenseGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game.hudNotifier,
      builder: (context, _) {
        final hud = game.hudNotifier;
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black87,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip(Icons.monetization_on, '${hud.gold}g', Colors.amber),
                _chip(Icons.favorite, '${hud.lives}', Colors.red),
                _chip(Icons.waves, 'Wave ${hud.wave}/10', Colors.cyan),
                ElevatedButton.icon(
                  onPressed:
                      hud.waveInProgress ? null : game.startNextWave,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                      hud.waveInProgress ? 'Fighting…' : 'Next Wave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}

// ─── Tower selection menu ──────────────────────────────────────────────────────

class TowerMenuOverlay extends StatefulWidget {
  final TowerDefenseGame game;
  const TowerMenuOverlay({super.key, required this.game});

  @override
  State<TowerMenuOverlay> createState() => _TowerMenuOverlayState();
}

class _TowerMenuOverlayState extends State<TowerMenuOverlay> {
  int _selected = 0;

  static const _defs = [
    {'name': 'Archer',  'cost': 50,  'sprite': 'assets/images/sprites/tower_archer.png',  'color': Color(0xFF4CAF50)},
    {'name': 'Mage',    'cost': 80,  'sprite': 'assets/images/sprites/tower_mage.png',    'color': Color(0xFF9C27B0)},
    {'name': 'Thunder', 'cost': 120, 'sprite': 'assets/images/sprites/tower_thunder.png', 'color': Color(0xFFFFEB3B)},
    {'name': 'Wind',    'cost': 100, 'sprite': 'assets/images/sprites/tower_wind.png',    'color': Color(0xFF00BCD4)},
  ];

  @override
  Widget build(BuildContext context) {
    widget.game.selectedTowerType = _selected;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tap tower to select • tap again to upgrade',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_defs.length, (i) {
                final def = _defs[i];
                final sel = i == _selected;
                final color = def['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.25) : Colors.transparent,
                      border: Border.all(
                        color: sel ? color : Colors.grey.shade700,
                        width: sel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                            def['sprite'] as String,
                            width: 40,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.layers, size: 28, color: Colors.white54),
                          ),
                        const SizedBox(height: 2),
                        Text(def['name'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                        Text('${def['cost']}g',
                            style:
                                TextStyle(color: color, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Game Over ────────────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  final TowerDefenseGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: game.restartGame,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Victory ──────────────────────────────────────────────────────────────────

class VictoryOverlay extends StatelessWidget {
  final TowerDefenseGame game;
  const VictoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('VICTORY! 🏆',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('All 10 waves defeated!',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: game.restartGame,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber),
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
