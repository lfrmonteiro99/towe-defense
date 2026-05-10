import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

class Projectile extends PositionComponent {
  final Enemy target;
  final double damage;
  final double speed;
  final Color color;
  final double radius;

  Projectile({
    required Vector2 startPos,
    required this.target,
    required this.damage,
    this.speed = 300,
    this.color = Colors.yellow,
    this.radius = 5,
  }) {
    position = startPos.clone();
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    if (target.isDead || target.reachedEnd) {
      removeFromParent();
      return;
    }
    final dir = target.position - position;
    final dist = dir.length;
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
    canvas.drawCircle(Offset.zero, radius, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}
