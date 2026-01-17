import 'package:flutter/material.dart';
import 'dart:async';
import 'package:game_3/models/assessment_models.dart';

class StepBuilderGame extends StatefulWidget {
  final int ageGroup;
  final Function(StepGameResult)? onGameFinished; // ✅ NEW: Callback instead of Navigator.pop

  const StepBuilderGame({
    super.key,
    this.ageGroup = 0,
    this.onGameFinished,
  });

  @override
  State<StepBuilderGame> createState() => _StepBuilderGameState();
}

class _StepBuilderGameState extends State<StepBuilderGame> {
  // ⏱️ GAME TIMING
  static const int totalGameDuration = 120; // 30s instruction + 90s build
  static const int instructionDuration = 30; // 30 seconds instruction
  int elapsedSeconds = 0;
  late DateTime gameStartTime;
  late Timer gameTimer;
  bool gameFinished = false;

  // 🎮 GAME STATE
  int currentPhase = 0; // 0 = Instruction, 1 = Build
  bool showInstructionCards = true;

  // 📋 METRICS
  int stepsSkipped = 0;
  int orderErrors = 0;
  bool taskCompleted = false;
  List<int> stepPlacementTimes = [];
  List<int> correctOrder = [0, 1, 2, 3, 4, 5];
  int nextExpectedStep = 0;

  final List<String> steps = [
    "Wake up and brush teeth",
    "Eat a healthy breakfast",
    "Get dressed in school clothes",
    "Pack your backpack",
    "Put on shoes",
    "Leave for school",
  ];

  // ✅ NEW: Shuffled display order for build phase
  late List<int> shuffledIndices;

  @override
  void initState() {
    super.initState();
    gameStartTime = DateTime.now();
    // ✅ Shuffle steps for display but keep track of correct order
    shuffledIndices = List<int>.from(correctOrder);
    shuffledIndices.shuffle();
    startGameTimer();
  }

  // ────────────────────── GAME TIMER ──────────────────────
  void startGameTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameFinished) return;

      setState(() {
        elapsedSeconds++;
      });

      // Debug logging
      if (elapsedSeconds % 10 == 0 || elapsedSeconds == totalGameDuration) {
        debugPrint("⏱️ STEP BUILDER TIMER: $elapsedSeconds/$totalGameDuration seconds");
      }

      // Phase transition: After instruction phase
      if (currentPhase == 0 && elapsedSeconds >= instructionDuration) {
        setState(() {
          currentPhase = 1;
          showInstructionCards = false;
        });
        debugPrint("✅ INSTRUCTION PHASE COMPLETE, STARTING BUILD PHASE");
      }

      // Check if total game time is up
      if (elapsedSeconds >= totalGameDuration && !gameFinished) {
        debugPrint("⏰ TIME UP! Calling finishGame()");
        finishGame();
      }
    });
  }

  // ────────────────────── STEP PLACEMENT ──────────────────────
  void onStepPlaced(int stepIndex) {
    int placementTime = DateTime.now().difference(gameStartTime).inMilliseconds;
    stepPlacementTimes.add(placementTime);

    // ✅ Check if this is the correct next step
    if (stepIndex == correctOrder[nextExpectedStep]) {
      debugPrint("✅ CORRECT: Step $stepIndex placed in correct order");
      nextExpectedStep++;
      
      if (nextExpectedStep >= correctOrder.length) {
        // All steps placed correctly
        setState(() => taskCompleted = true);
        debugPrint("🎉 TASK COMPLETED - All steps placed in correct order!");
      }
    } else {
      // Wrong order
      orderErrors++;
      debugPrint("❌ ORDER ERROR: Expected ${correctOrder[nextExpectedStep]}, got $stepIndex");
    }
  }

  void onStepSkipped() {
    stepsSkipped++;
    debugPrint("⏭️ STEP SKIPPED");
  }

  // ────────────────────── GAME COMPLETION ──────────────────────
  void finishGame() {
    if (gameFinished) return;
    gameFinished = true;

    debugPrint("🏁 STEP BUILDER GAME FINISHED - elapsedSeconds: $elapsedSeconds, stepsSkipped: $stepsSkipped, orderErrors: $orderErrors");

    gameTimer.cancel();

    StepGameResult result = StepGameResult(
      stepsSkipped: stepsSkipped,
      orderErrors: orderErrors,
      taskCompleted: taskCompleted,
      stepPlacementTimes: stepPlacementTimes,
      startTime: gameStartTime,
      endTime: DateTime.now(),
      ageGroup: widget.ageGroup,
    );

    debugPrint("🚀 CALLING CALLBACK (not Navigator.pop)");
    if (widget.onGameFinished != null) {
      widget.onGameFinished!(result);
    }
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
      backgroundColor: Colors.purple.shade50,
      body: SafeArea(
        child: currentPhase == 0
            ? _buildInstructionPhase(minutes, seconds)
            : _buildBuildPhase(minutes, seconds),
      ),
    );
  }

  // Instruction Phase UI
  Widget _buildInstructionPhase(int minutes, int seconds) {
    double opacity = (instructionDuration - elapsedSeconds) / instructionDuration;
    opacity = opacity.clamp(0, 1);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              child: const Text(
                "🎯 Watch the Order",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Show cards in correct order
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.5,
              ),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                return Opacity(
                  opacity: opacity,
                  child: Card(
                    elevation: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade300,
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          steps[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$minutes:${seconds.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Phase UI
  Widget _buildBuildPhase(int minutes, int seconds) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "🏗️ Build Phase",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$minutes:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Drag blocks to build the tower in order",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                // Display steps to place (SHUFFLED)
                Expanded(
                  child: ListView.builder(
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final shuffledStepIndex = shuffledIndices[index];
                      bool isPlaced = shuffledStepIndex < nextExpectedStep; // ✅ Already placed
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: !isPlaced
                              ? () {
                                  // User clicked on shuffledStepIndex, validate it
                                  int placementTime = DateTime.now().difference(gameStartTime).inMilliseconds;
                                  stepPlacementTimes.add(placementTime);
                                  
                                  if (shuffledStepIndex == nextExpectedStep) {
                                    // ✅ Correct! This is the next step they need
                                    nextExpectedStep++;
                                    debugPrint('✅ Correct step! Now at step $nextExpectedStep/${steps.length}');
                                    
                                    // Check if all steps placed correctly
                                    if (nextExpectedStep >= steps.length) {
                                      taskCompleted = true;
                                      debugPrint('🎉 TASK COMPLETED - All steps placed in correct order!');
                                    }
                                  } else {
                                    // ❌ Wrong! They picked the wrong step
                                    orderErrors++;
                                    debugPrint('❌ Wrong step! Expected $nextExpectedStep, got $shuffledStepIndex');
                                  }
                                  setState(() {});
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isPlaced
                                  ? Colors.grey.shade300.withOpacity(0.5)
                                  : Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  steps[shuffledStepIndex],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isPlaced ? Colors.grey : Colors.white,
                                  ),
                                ),
                                if (!isPlaced)
                                  const Icon(
                                    Icons.drag_indicator,
                                    color: Colors.white,
                                  )
                                else
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow("Steps Placed", "$nextExpectedStep/${steps.length}"),
                      const SizedBox(height: 8),
                      _buildStatRow("Order Errors", orderErrors.toString()),
                      const SizedBox(height: 8),
                      _buildStatRow("Steps Skipped", stepsSkipped.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }
}
