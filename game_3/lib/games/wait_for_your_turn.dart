import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:game_3/models/assessment_models.dart';

class WaitForYourTurn4 extends StatefulWidget {
  final int ageGroup;
  final Function(WaitingGameResult)? onGameFinished; // ✅ NEW: Callback instead of Navigator.pop

  const WaitForYourTurn4({
    super.key, 
    required this.ageGroup,
    this.onGameFinished,
  });

  @override
  State<WaitForYourTurn4> createState() => _WaitForYourTurn4State();
}

class _WaitForYourTurn4State extends State<WaitForYourTurn4> {
  // ⏱️ GAME TIMING
  static const int totalGameDuration = 120; // 2 minutes
  static const int practiceRoundDuration = 30; // 30 seconds
  int elapsedSeconds = 0;
  late DateTime gameStartTime;
  bool isPracticeRound = true;
  bool gameFinished = false; // ✅ NEW: Prevent multiple finishes

  // 🎮 ROUND CONTROL
  int countdown = 3;
  bool goSignal = false;
  DateTime? goTime;
  bool canTap = true;

  // 📊 METRICS
  int prematureTaps = 0;
  List<int> reactionTimes = [];
  int totalTrials = 0;

  late Timer gameTimer;

  @override
  void initState() {
    super.initState();
    gameStartTime = DateTime.now();
    startGameTimer();
    startRound();
  }

  // ────────────────────── GAME TIMER ──────────────────────
  void startGameTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameFinished) return; // ✅ Exit if game already finished

      setState(() {
        elapsedSeconds++;
      });

      // Debug logging every 10 seconds
      if (elapsedSeconds % 10 == 0 || elapsedSeconds == 120) {
        debugPrint("⏱️ WAIT GAME TIMER: $elapsedSeconds/$totalGameDuration seconds");
      }

      // Check if practice round is over
      if (isPracticeRound && elapsedSeconds >= practiceRoundDuration) {
        setState(() => isPracticeRound = false);
        debugPrint("✅ PRACTICE ROUND COMPLETE, STARTING MAIN GAME");
      }

      // Check if total game time is up (2 minutes)
      if (elapsedSeconds >= totalGameDuration && !gameFinished) {
        debugPrint("⏰ TIME UP! Calling finishGame()");
        finishGame();
      }
    });
  }

  // ────────────────────── ROUND LOGIC ──────────────────────
  Future<void> startRound() async {
    if (!mounted || gameFinished) return; // ✅ Exit if game finished

    // Check if game time is already up
    if (elapsedSeconds >= totalGameDuration) {
      finishGame();
      return;
    }

    // Random countdown: 2-15 seconds
    int startValue = isPracticeRound ? 3 : Random().nextInt(14) + 2; // 2-15

    setState(() {
      countdown = startValue;
      goSignal = false;
      goTime = null;
      canTap = true;
    });

    // Countdown animation
    for (int i = startValue; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || gameFinished || elapsedSeconds >= totalGameDuration) return;
      setState(() => countdown = i - 1);
    }

    // GO signal!
    if (mounted && !gameFinished && elapsedSeconds < totalGameDuration) {
      setState(() {
        goSignal = true;
        goTime = DateTime.now();
        totalTrials++;
      });
    }
  }

  // ────────────────────── TAP HANDLER ──────────────────────
  void handleTap() {
    if (!canTap) return; // Prevent multiple taps in one round

    if (!goSignal) {
      // Premature tap - before GO
      setState(() {
        prematureTaps++;
        canTap = false;
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Oops — wait a little 😊"),
          duration: Duration(milliseconds: 500),
        ),
      );

      // Start next round after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !gameFinished) {
          startRound();
        }
      });
    } else {
      // Correct tap - after GO
      int reactionTime =
          DateTime.now().difference(goTime!).inMilliseconds;
      setState(() {
        reactionTimes.add(reactionTime);
        canTap = false;
      });

      // Start next round
      if (elapsedSeconds < totalGameDuration && !gameFinished) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !gameFinished) {
            startRound();
          }
        });
      }
    }
  }

  // ────────────────────── GAME COMPLETION ──────────────────────
  void finishGame() {
    if (gameFinished) return; // ✅ Prevent duplicate calls
    gameFinished = true;

    debugPrint("🏁 WAIT GAME FINISHED - elapsedSeconds: $elapsedSeconds, prematureTaps: $prematureTaps, totalTrials: $totalTrials");

    gameTimer.cancel();

    WaitingGameResult result = WaitingGameResult(
      prematureTaps: prematureTaps,
      reactionTimes: reactionTimes,
      avgReaction: averageReaction,
      reactionVariability: reactionVariability,
      totalTrials: totalTrials,
      startTime: gameStartTime,
      endTime: DateTime.now(),
      ageGroup: widget.ageGroup,
    );

    debugPrint("🚀 CALLING CALLBACK (not Navigator.pop)");
    // ✅ Use callback instead of Navigator.pop to avoid locked state
    if (widget.onGameFinished != null) {
      widget.onGameFinished!(result);
    }
  }

  // ────────────────────── DATA METRICS ──────────────────────
  double get averageReaction {
    if (reactionTimes.isEmpty) return 0;
    return reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
  }

  double get reactionVariability {
    if (reactionTimes.length < 2) return 0;
    double mean = averageReaction;
    double sum = 0;
    for (int rt in reactionTimes) {
      sum += pow(rt - mean, 2);
    }
    return sqrt(sum / reactionTimes.length);
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  // ────────────────────── UI ──────────────────────
  @override
  Widget build(BuildContext context) {
    int remainingSeconds = totalGameDuration - elapsedSeconds;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    return Scaffold(
      backgroundColor: goSignal ? Colors.green : Colors.blue,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPracticeRound ? "🏫 Practice Round" : "🎮 Main Game",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Countdown display
              Text(
                goSignal ? "GO!" : countdown.toString(),
                style: const TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Instructions
              Text(
                goSignal ? "TAP NOW!" : "Wait…",
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 60),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$minutes:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    StatRow(
                      label: "Correct Taps",
                      value: "${reactionTimes.length}",
                    ),
                    const SizedBox(height: 12),
                    StatRow(
                      label: "Premature Taps",
                      value: "$prematureTaps",
                    ),
                    const SizedBox(height: 12),
                    StatRow(
                      label: "Avg Reaction",
                      value:
                          "${averageReaction.toStringAsFixed(0)} ms",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────── STAT ROW WIDGET ──────────────────────
class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
