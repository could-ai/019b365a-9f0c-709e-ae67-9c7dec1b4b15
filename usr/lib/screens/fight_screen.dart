import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game_engine.dart';
import 'game_painter.dart';

class FightScreen extends StatefulWidget {
  const FightScreen({super.key});

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late GameEngine _engine;
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _ticker = createTicker(_onTick);
    _ticker.start();
    _focusNode.requestFocus();
  }

  void _onTick(Duration elapsed) {
    _engine.handleInput(_pressedKeys);
    _engine.update(0.016); // Approx 60 FPS
    setState(() {}); // Trigger repaint
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update screen size in engine
    _engine.screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            _pressedKeys.add(event.data.logicalKey);
          } else if (event is RawKeyUpEvent) {
            _pressedKeys.remove(event.data.logicalKey);
          }
        },
        child: Stack(
          children: [
            // Game Canvas
            SizedBox.expand(
              child: CustomPaint(
                painter: GamePainter(_engine),
              ),
            ),
            
            // HUD (Heads Up Display)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Player 1 Health
                  _buildHealthBar(_engine.player1, false),
                  
                  // Timer / VS
                  const Text(
                    "VS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic
                    ),
                  ),
                  
                  // Player 2 Health
                  _buildHealthBar(_engine.player2, true),
                ],
              ),
            ),

            // Controls Hint
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "CONTROLS: W (Jump) A/D (Move) S (Crouch) F (Punch) G (Kick)",
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ),

            // Game Over Overlay
            if (_engine.player1.state == FighterState.dead || _engine.player2.state == FighterState.dead)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black87,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _engine.player1.state == FighterState.dead ? "${_engine.player2.name} WINS" : "${_engine.player1.name} WINS",
                        style: const TextStyle(color: Colors.red, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _engine.reset();
                        },
                        child: const Text("REMATCH"),
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(Fighter fighter, bool isRight) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          fighter.name,
          style: TextStyle(
            color: fighter.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))]
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.grey[800],
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: fighter.health / fighter.maxHealth,
                alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  color: fighter.health > 30 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
