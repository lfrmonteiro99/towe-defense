import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

class Projectile extends SpriteComponent {
  final Enemy target;
  final double damage;
  final double speed;
  final String spriteName;

  Projectile({
    required Vector2 startPos,
    required this.target,
    required this.damage,
    required this.spriteName,
    this.speed = 300,
  }) {
    position = startPos.clone();
    anchor = Anchor.center;
    size = Vector2(32, 14);
  }

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(spriteName);
  }

  @override
  void update(double dt) {
    if (target.isDead || target.reachedEnd) {
      removeFromParent();
      return;
    }
    final dir = target.position - position;
    final dist = dir.length;

    // Rotate to face direction of travel
    if (dir.length2 > 0.01) {
      angle = dir.screenAngle();
    }

    final step = speed * dt;
    if (step >= dist) {
      target.takeDamage(damage);
      removeFromParent();
    } else {
      position += dir.normalized() * step;
    }
  }

  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      // Fallback circle if sprite not loaded yet
      canvas.drawCircle(Offset.zero, 5, Paint()..color = Colors.yellow);
      return;
    }
    super.render(canvas);
  }
}
