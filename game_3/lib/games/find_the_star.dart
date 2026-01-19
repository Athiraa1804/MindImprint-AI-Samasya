import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/assessment_models.dart';

class FindTheStarGame extends StatefulWidget {
  final int ageGroup;
  final Function(FindStarGameResult)? onGameFinished;

  const FindTheStarGame({
    Key? key,
    required this.ageGroup,
    this.onGameFinished,
  }) : super(key: key);

  @override
  State<FindTheStarGame> createState() => _FindTheStarGameState();
}

class _FindTheStarGameState extends State<FindTheStarGame> {
  late Timer gameTimer;
  int elapsedSeconds = 0;
  final int totalGameDuration = 60; // 1 minute
  int starsFound = 0;
  int totalMisclicks = 0;
  List<int> timesPerStar = []; // Time to click each star in milliseconds
  DateTime? currentStarStartTime;
  bool gameFinished = false;

  late List<ShapeData> shapes = [];
  late int targetStarIndex;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Generate shapes after dependencies are available
    if (shapes.isEmpty) {
      generateNewRound();
    }
  }

  void startGame() {
    debugPrint("🌟 STAR GAME STARTED");
    currentStarStartTime = DateTime.now();
    startTimer();
    // DO NOT call generateNewRound() here - it will be called in didChangeDependencies()
  }

  void startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || gameFinished || elapsedSeconds >= totalGameDuration) {
        timer.cancel();
        if (!gameFinished && elapsedSeconds >= totalGameDuration) {
          finishGame();
        }
        return;
      }

      setState(() {
        elapsedSeconds++;
        if (elapsedSeconds >= totalGameDuration) {
          finishGame();
        }
      });

      debugPrint("⏱️ STAR GAME TIMER: $elapsedSeconds/$totalGameDuration seconds");
    });
  }

  void generateNewRound() {
    shapes = [];
    // Generate 9 random shapes (8 non-stars + 1 star)
    final List<String> shapeTypes = [
      'star',
      'pentagon',
      'rectangle',
      'triangle',
      'diamond',
      'circle'
    ];

    // Create shapes with random positions
    for (int i = 0; i < 9; i++) {
      final isTarget = i == 0; // First shape is always the target star
      final shapeType = isTarget
          ? 'star'
          : shapeTypes[1 + random.nextInt(shapeTypes.length - 1)];

      final shape = ShapeData(
        type: shapeType,
        isTarget: isTarget,
        position: _generateRandomPosition(),
      );
      shapes.add(shape);
    }

    // Shuffle so the star isn't always in the first position
    shapes.shuffle(random);

    // Find the target star index
    targetStarIndex = shapes.indexWhere((s) => s.isTarget);

    if (mounted) {
      setState(() {});
    }
  }

  Offset _generateRandomPosition() {
    final screenSize = MediaQuery.of(context).size;
    final padding = 60.0;
    final shapeSize = 60.0;

    final x =
        padding + random.nextDouble() * (screenSize.width - padding * 2 - shapeSize);
    final y =
        padding + random.nextDouble() * (screenSize.height - padding * 2 - shapeSize - 100);

    return Offset(x, y);
  }

  void handleShapeClick(int index) {
    if (gameFinished) return;

    if (index == targetStarIndex) {
      // Correct click!
      int timeForThisStar =
          DateTime.now().difference(currentStarStartTime!).inMilliseconds;
      setState(() {
        starsFound++;
        timesPerStar.add(timeForThisStar);
      });

      debugPrint(
          "⭐ STAR FOUND! Total: $starsFound, Time: ${timeForThisStar}ms");

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⭐ Correct! Found the star!"),
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
        ),
      );

      // Generate next round
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !gameFinished) {
          currentStarStartTime = DateTime.now();
          generateNewRound();
        }
      });
    } else {
      // Misclick
      setState(() {
        totalMisclicks++;
      });

      debugPrint("❌ MISCLICK! Total misclicks: $totalMisclicks");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("❌ Wrong shape! Try again."),
          duration: const Duration(milliseconds: 400),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void finishGame() {
    if (gameFinished) return;
    gameFinished = true;

    gameTimer.cancel();

    debugPrint(
        "🏁 STAR GAME FINISHED - Stars Found: $starsFound, Total Misclicks: $totalMisclicks");

    final result = FindStarGameResult(
      starsFound: starsFound,
      totalMisclicks: totalMisclicks,
      timesPerStar: timesPerStar,
      avgTimePerStar: timesPerStar.isEmpty
          ? 0
          : timesPerStar.reduce((a, b) => a + b) / timesPerStar.length,
      startTime: DateTime.now().subtract(Duration(seconds: elapsedSeconds)),
      endTime: DateTime.now(),
      ageGroup: widget.ageGroup,
    );

    debugPrint("🚀 CALLING CALLBACK");
    if (widget.onGameFinished != null) {
      widget.onGameFinished!(result);
    }
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = totalGameDuration - elapsedSeconds;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {}, // Prevent accidental clicks on background
        child: Stack(
          children: [
            // Background
            Container(
              color: Colors.blue.shade900,
              child: Center(
                child: Text(
                  "Find the ⭐ STAR!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // Shapes
            ...List.generate(shapes.length, (index) {
              final shape = shapes[index];
              return Positioned(
                left: shape.position.dx,
                top: shape.position.dy,
                child: GestureDetector(
                  onTap: () => handleShapeClick(index),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _buildShape(shape),
                  ),
                ),
              );
            }),

            // Top Stats Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$minutes:${seconds.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Stars Found
                    Text(
                      "⭐ Found: $starsFound",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellowAccent,
                      ),
                    ),

                    // Misclicks
                    Text(
                      "❌ Misclicks: $totalMisclicks",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Help Text
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Click only on the ⭐ STAR",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShape(ShapeData shape) {
    const double size = 60;
    const double strokeWidth = 2.5;

    switch (shape.type) {
      case 'star':
        return CustomPaint(
          size: const Size(size, size),
          painter: StarPainter(
            color: Colors.white,
            strokeWidth: strokeWidth,
          ),
        );

      case 'pentagon':
        return CustomPaint(
          size: const Size(size, size),
          painter: PentagonPainter(
            color: Colors.white,
            strokeWidth: strokeWidth,
          ),
        );

      case 'rectangle':
        return Container(
          width: size,
          height: size * 0.7,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: strokeWidth),
            borderRadius: BorderRadius.circular(4),
          ),
        );

      case 'triangle':
        return CustomPaint(
          size: const Size(size, size),
          painter: TrianglePainter(
            color: Colors.white,
            strokeWidth: strokeWidth,
          ),
        );

      case 'diamond':
        return CustomPaint(
          size: const Size(size, size),
          painter: DiamondPainter(
            color: Colors.white,
            strokeWidth: strokeWidth,
          ),
        );

      case 'circle':
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: strokeWidth),
          ),
        );
    }
  }
}

// Shape Data Model
class ShapeData {
  final String type;
  final bool isTarget;
  final Offset position;

  ShapeData({
    required this.type,
    required this.isTarget,
    required this.position,
  });
}

// Custom Painters for Shapes
class PentagonPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  PentagonPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PentagonPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  TrianglePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, strokeWidth);
    path.lineTo(size.width - strokeWidth, size.height - strokeWidth);
    path.lineTo(strokeWidth, size.height - strokeWidth);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => false;
}

class DiamondPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiamondPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, strokeWidth);
    path.lineTo(size.width - strokeWidth, size.height / 2);
    path.lineTo(size.width / 2, size.height - strokeWidth);
    path.lineTo(strokeWidth, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DiamondPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  StarPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (size.width - strokeWidth) / 2;

    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * 3.14159 / 180;
      final distance = i.isEven ? radius : radius * 0.4;
      final x = centerX + distance * cos(angle);
      final y = centerY + distance * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) => false;
}
