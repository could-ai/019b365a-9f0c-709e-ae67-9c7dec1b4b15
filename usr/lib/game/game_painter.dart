import 'package:flutter/material.dart';
import 'game_engine.dart';

class GamePainter extends CustomPainter {
  final GameEngine game;

  GamePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Background
    _drawBackground(canvas, size);

    // Draw Fighters
    _drawFighter(canvas, game.player1);
    _drawFighter(canvas, game.player2);

    // Draw Particles
    Paint particlePaint = Paint();
    for (var p in game.particles) {
      particlePaint.color = p.color.withOpacity(p.life);
      canvas.drawRect(Rect.fromLTWH(p.x, p.y, 4, 4), particlePaint);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Sky
    var paint = Paint()..color = const Color(0xFF202040);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Moon
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(const Offset(100, 100), 40, paint);

    // Floor
    paint.color = const Color(0xFF101020);
    canvas.drawRect(Rect.fromLTWH(0, size.height - kGroundHeight, size.width, kGroundHeight), paint);
    
    // Grid/Details
    paint.color = Colors.white.withOpacity(0.1);
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i, size.height - kGroundHeight), 
        Offset(i - 100, size.height), 
        paint
      );
    }
  }

  void _drawFighter(Canvas canvas, Fighter fighter) {
    Paint paint = Paint()
      ..color = fighter.color
      ..style = PaintingStyle.fill;

    Paint skinPaint = Paint()..color = const Color(0xFFFFCCAA);
    Paint blackPaint = Paint()..color = Colors.black;

    canvas.save();
    canvas.translate(fighter.x, fighter.y);
    
    // Flip if facing left
    if (fighter.facing == Direction.left) {
      canvas.scale(-1, 1);
    }

    // --- Drawing the Ninja ---
    
    // Legs
    // Simple animation based on state
    double legOffset = 0;
    if (fighter.state == FighterState.walk) {
      legOffset = (fighter.stateTimer % 10 - 5).toDouble() * 2;
    }

    // Back Leg
    canvas.drawRect(Rect.fromLTWH(-15 + legOffset, -50, 10, 50), blackPaint);
    // Front Leg
    canvas.drawRect(Rect.fromLTWH(5 - legOffset, -50, 10, 50), blackPaint);

    // Torso (Vest)
    Path torso = Path();
    torso.moveTo(-20, -90);
    torso.lineTo(20, -90);
    torso.lineTo(15, -50);
    torso.lineTo(-15, -50);
    torso.close();
    canvas.drawPath(torso, blackPaint); // Undersuit
    
    // Colored Vest
    Path vest = Path();
    vest.moveTo(-20, -90);
    vest.lineTo(-10, -50);
    vest.lineTo(10, -50);
    vest.lineTo(20, -90);
    vest.lineTo(0, -50); // V shape
    vest.close();
    canvas.drawPath(vest, paint);

    // Head
    canvas.drawCircle(const Offset(0, -100), 12, skinPaint); // Face
    
    // Mask
    Path mask = Path();
    mask.moveTo(-11, -100);
    mask.quadraticBezierTo(0, -88, 11, -100);
    mask.lineTo(11, -105); // Top of mask
    mask.lineTo(-11, -105);
    mask.close();
    canvas.drawPath(mask, paint);
    
    // Hood
    canvas.drawArc(Rect.fromCircle(center: const Offset(0, -100), radius: 13), 3.14, 3.14, true, blackPaint);

    // Arms
    // Animate arms
    double armAngle = 0;
    double armX = 0;
    double armY = -80;
    
    if (fighter.state == FighterState.punch) {
      armAngle = -1.5; // Punch forward
      armX = 10;
    } else if (fighter.state == FighterState.idle) {
      armAngle = 0.5; // Guard
    }

    canvas.save();
    canvas.translate(armX, armY);
    canvas.rotate(armAngle);
    canvas.drawRect(const Rect.fromLTWH(-5, 0, 10, 35), skinPaint); // Arm
    canvas.drawRect(const Rect.fromLTWH(-6, 0, 12, 10), paint); // Shoulder pad
    canvas.drawCircle(const Offset(0, 35), 6, skinPaint); // Fist
    canvas.restore();

    // Kick Leg Override
    if (fighter.state == FighterState.kick) {
      canvas.save();
      canvas.translate(10, -50);
      canvas.rotate(-1.5); // Kick up
      canvas.drawRect(const Rect.fromLTWH(0, 0, 10, 50), blackPaint);
      canvas.restore();
    }

    // Hit Effect (Flash White)
    if (fighter.state == FighterState.hit) {
       canvas.drawCircle(const Offset(0, -60), 40, Paint()..color = Colors.white.withOpacity(0.5));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
