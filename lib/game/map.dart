import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'tower_defense_game.dart';

const int kCols = 20;
const int kRows = 14;

// Tile types
const int tileGrass = 0;
const int tilePath = 1;

// The fixed path as a list of (col, row) waypoints
const List<(int, int)> kPathWaypoints = [
  (0, 3),
  (3, 3),
  (3, 6),
  (7, 6),
  (7, 2),
  (12, 2),
  (12, 8),
  (16, 8),
  (16, 4),
  (19, 4),
];

class GameMap extends Component with HasGameRef<TowerDefenseGame> {
  late List<List<int>> grid;
  late double tileSize;
  late List<Vector2> pathPoints;

  @override
  Future<void> onLoad() async {
    _computeTileSize();
    _buildGrid();
    _buildPathPoints();
  }

  void _computeTileSize() {
    final size = gameRef.size;
    final tw = size.x / kCols;
    final th = (size.y - 120) / kRows; // leave room for HUD and tower menu
    tileSize = tw < th ? tw : th;
  }

  void _buildGrid() {
    grid = List.generate(kRows, (_) => List.filled(kCols, tileGrass));
    // Mark path tiles
    for (int i = 0; i < kPathWaypoints.length - 1; i++) {
      final (c1, r1) = kPathWaypoints[i];
      final (c2, r2) = kPathWaypoints[i + 1];
      if (r1 == r2) {
        final minC = c1 < c2 ? c1 : c2;
        final maxC = c1 > c2 ? c1 : c2;
        for (int c = minC; c <= maxC; c++) {
          if (r1 >= 0 && r1 < kRows && c >= 0 && c < kCols) {
            grid[r1][c] = tilePath;
          }
        }
      } else {
        final minR = r1 < r2 ? r1 : r2;
        final maxR = r1 > r2 ? r1 : r2;
        for (int r = minR; r <= maxR; r++) {
          if (r >= 0 && r < kRows && c1 >= 0 && c1 < kCols) {
            grid[r][c1] = tilePath;
          }
        }
      }
    }
  }

  void _buildPathPoints() {
    pathPoints = kPathWaypoints.map((wp) {
      final (c, r) = wp;
      return tileCenter(c, r);
    }).toList();
  }

  Vector2 tileCenter(int col, int row) {
    return Vector2(
      col * tileSize + tileSize / 2,
      row * tileSize + tileSize / 2 + 44, // offset for top HUD bar
    );
  }

  Vector2 tileTopLeft(int col, int row) {
    return Vector2(col * tileSize, row * tileSize + 44);
  }

  bool isPathTile(int col, int row) {
    if (row < 0 || row >= kRows || col < 0 || col >= kCols) return false;
    return grid[row][col] == tilePath;
  }

  (int, int)? screenToTile(Vector2 screenPos) {
    final col = ((screenPos.x) / tileSize).floor();
    final row = ((screenPos.y - 44) / tileSize).floor();
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return null;
    return (col, row);
  }

  @override
  void render(Canvas canvas) {
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        final rect = Rect.fromLTWH(
          c * tileSize,
          r * tileSize + 44,
          tileSize,
          tileSize,
        );
        final isPath = grid[r][c] == tilePath;
        canvas.drawRect(
          rect,
          Paint()
            ..color = isPath
                ? const Color(0xFF8B6914)
                : const Color(0xFF2D5A27),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.black26
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }
    // Draw path arrows for clarity
    _drawPathArrows(canvas);
  }

  void _drawPathArrows(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      canvas.drawLine(
        pathPoints[i].toOffset(),
        pathPoints[i + 1].toOffset(),
        paint,
      );
    }
  }
}
