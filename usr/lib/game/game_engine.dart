import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// --- Enums ---
enum FighterState { idle, walk, jump, crouch, punch, kick, hit, dead, win }
enum Direction { left, right }

// --- Constants ---
const double kGravity = 0.8;
const double kGroundHeight = 50.0; // Distance from bottom
const double kMoveSpeed = 5.0;
const double kJumpForce = -18.0;
const double kFighterWidth = 60.0;
const double kFighterHeight = 120.0;

// --- Models ---

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double life; // 1.0 to 0.0

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.life = 1.0,
  });
}

class Fighter {
  double x;
  double y;
  double vx;
  double vy;
  double health;
  double maxHealth;
  FighterState state;
  Direction facing;
  Color color;
  String name;
  
  // Animation timers
  int frame = 0;
  int stateTimer = 0;

  // Hitbox for attacks
  Rect? attackBox;

  Fighter({
    required this.x,
    required this.y,
    required this.color,
    required this.name,
    this.facing = Direction.right,
  })  : vx = 0,
        vy = 0,
        health = 100,
        maxHealth = 100,
        state = FighterState.idle;

  Rect get bodyRect => Rect.fromLTWH(x - kFighterWidth / 2, y - kFighterHeight, kFighterWidth, kFighterHeight);

  void update(double screenWidth, double screenHeight) {
    if (state == FighterState.dead) return;

    // Apply Gravity
    vy += kGravity;

    // Apply Velocity
    x += vx;
    y += vy;

    // Ground Collision
    if (y >= screenHeight - kGroundHeight) {
      y = screenHeight - kGroundHeight;
      vy = 0;
      if (state == FighterState.jump) {
        state = FighterState.idle;
      }
    }

    // Wall Collision
    if (x < kFighterWidth / 2) x = kFighterWidth / 2;
    if (x > screenWidth - kFighterWidth / 2) x = screenWidth - kFighterWidth / 2;

    // Friction
    if (state != FighterState.jump) {
      vx *= 0.8; // Ground friction
    } else {
      vx *= 0.95; // Air resistance
    }

    if (vx.abs() < 0.1) vx = 0;

    // State Management
    stateTimer++;
    
    // Reset attack states after duration
    if ((state == FighterState.punch || state == FighterState.kick) && stateTimer > 15) {
      state = FighterState.idle;
      attackBox = null;
    }

    // Reset hit state
    if (state == FighterState.hit && stateTimer > 20) {
      state = FighterState.idle;
    }
  }

  void jump() {
    if (y >= 500 - kGroundHeight - 5) { // Approximate ground check
      vy = kJumpForce;
      state = FighterState.jump;
    }
  }

  void move(double dir) {
    if (state == FighterState.crouch || state == FighterState.hit || state == FighterState.dead) return;
    vx = dir * kMoveSpeed;
    if (dir > 0) facing = Direction.right;
    if (dir < 0) facing = Direction.left;
    if (state == FighterState.idle) state = FighterState.walk;
  }

  void attack(FighterState type) {
    if (state == FighterState.hit || state == FighterState.dead || state == FighterState.punch || state == FighterState.kick) return;
    
    state = type;
    stateTimer = 0;
    
    // Define attack hitbox based on facing
    double reach = (type == FighterState.kick) ? 70.0 : 50.0;
    double offsetX = (facing == Direction.right) ? kFighterWidth / 2 : -kFighterWidth / 2 - reach;
    
    attackBox = Rect.fromLTWH(
      x + offsetX, 
      y - kFighterHeight * 0.8, // Upper body
      reach, 
      40
    );
  }

  void takeDamage(double amount) {
    if (state == FighterState.dead) return;
    health -= amount;
    state = FighterState.hit;
    stateTimer = 0;
    attackBox = null; // Cancel attack if hit
    if (health <= 0) {
      health = 0;
      state = FighterState.dead;
    }
  }
}

// --- Game Engine ---

class GameEngine extends ChangeNotifier {
  late Fighter player1;
  late Fighter player2;
  List<Particle> particles = [];
  Size screenSize = const Size(800, 600);
  Random rng = Random();

  GameEngine() {
    reset();
  }

  void reset() {
    player1 = Fighter(x: 200, y: 500, color: Colors.yellow, name: "SCORPION");
    player2 = Fighter(x: 600, y: 500, color: Colors.blue, name: "SUB-ZERO", facing: Direction.left);
    particles.clear();
    notifyListeners();
  }

  void update(double dt) {
    // Update Physics
    player1.update(screenSize.width, screenSize.height);
    player2.update(screenSize.width, screenSize.height);

    // AI for Player 2 (Simple)
    _updateAI();

    // Collision Detection (Attacks)
    _checkAttack(player1, player2);
    _checkAttack(player2, player1);

    // Particles
    for (int i = particles.length - 1; i >= 0; i--) {
      Particle p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.5; // Gravity
      p.life -= 0.05;
      if (p.life <= 0) {
        particles.removeAt(i);
      }
    }

    notifyListeners();
  }

  void _updateAI() {
    if (player2.state == FighterState.dead || player2.state == FighterState.hit) return;
    if (player1.state == FighterState.dead) {
       player2.state = FighterState.win;
       return;
    }

    double dist = (player1.x - player2.x).abs();
    double dx = player1.x - player2.x;

    // Face player
    if (dx > 0) player2.facing = Direction.right;
    else player2.facing = Direction.left;

    // Simple Logic
    if (dist > 100) {
      // Move closer
      player2.move(dx > 0 ? 0.8 : -0.8);
    } else {
      // Attack chance
      if (rng.nextInt(100) < 5) {
        player2.attack(FighterState.punch);
      } else if (rng.nextInt(100) < 2) {
        player2.attack(FighterState.kick);
      }
    }
  }

  void _checkAttack(Fighter attacker, Fighter defender) {
    if (attacker.attackBox != null && defender.state != FighterState.dead) {
      if (attacker.attackBox!.overlaps(defender.bodyRect)) {
        // Hit!
        defender.takeDamage(10);
        attacker.attackBox = null; // Consume attack
        
        // Spawn Blood
        _spawnBlood(defender.x, defender.y - kFighterHeight / 2);
        
        // Knockback
        defender.vx = (attacker.x < defender.x) ? 10 : -10;
        defender.vy = -5;
      }
    }
  }

  void _spawnBlood(double x, double y) {
    for (int i = 0; i < 10; i++) {
      particles.add(Particle(
        x: x,
        y: y,
        vx: (rng.nextDouble() - 0.5) * 10,
        vy: (rng.nextDouble() - 0.5) * 10,
        color: Colors.red,
      ));
    }
  }

  // Input Handling
  void handleInput(Set<LogicalKeyboardKey> keys) {
    if (player1.state == FighterState.dead || player1.state == FighterState.hit) return;

    // Movement
    if (keys.contains(LogicalKeyboardKey.keyA)) {
      player1.move(-1.0);
    } else if (keys.contains(LogicalKeyboardKey.keyD)) {
      player1.move(1.0);
    } else {
      if (player1.state == FighterState.walk) player1.state = FighterState.idle;
    }

    // Jump
    if (keys.contains(LogicalKeyboardKey.keyW)) {
      player1.jump();
    }

    // Crouch
    if (keys.contains(LogicalKeyboardKey.keyS)) {
      player1.state = FighterState.crouch;
    } else if (player1.state == FighterState.crouch) {
      player1.state = FighterState.idle;
    }

    // Attacks
    if (keys.contains(LogicalKeyboardKey.keyF)) {
      player1.attack(FighterState.punch);
    }
    if (keys.contains(LogicalKeyboardKey.keyG)) {
      player1.attack(FighterState.kick);
    }
  }
}
