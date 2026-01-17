import 'package:flutter/material.dart';
import 'dart:async';
import 'package:game_3/models/assessment_models.dart';

class ReadingStoryGame extends StatefulWidget {
  final Function(StoryGameResult)? onGameFinished;

  const ReadingStoryGame({super.key, this.onGameFinished});

  @override
  State<ReadingStoryGame> createState() => _ReadingStoryGameState();
}

class _ReadingStoryGameState extends State<ReadingStoryGame> {
  // ✅ LONGER STORIES - 3 sentences per slide
  final List<String> storyPages = [
    "🌟 The Brave Little Cloud 🌟\n\n"
        "High above the hills lived a small, fluffy cloud named Piku. "
        "Piku loved to travel across the sky and watch birds fly below. "
        "Every day, Piku would race with the wind and paint beautiful patterns in the sky.",

    "One bright morning, the wind whispered softly, "
        "\"Piku, it's time to help the earth.\" "
        "Piku felt excited and proud, knowing that something important was about to happen. "
        "The other clouds gathered around to wish Piku good luck on this special journey.",

    "Slowly, Piku turned into tiny raindrops and fell gently onto the ground. "
        "Flowers smiled as the water touched their petals, trees danced with joy, and the earth felt happy again. 🌧️🌸 "
        "Piku realized that even small actions, when done with love, can make the whole world more beautiful."
  ];

  int currentPage = 0;
  DateTime? pageStartTime;

  // ⏱️ GAME TIMING
  static const int totalGameDuration = 300; // 5 minutes
  int elapsedSeconds = 0;
  late DateTime gameStartTime;
  late Timer gameTimer;
  bool gameFinished = false;

  // -------- BEHAVIOR DATA --------
  List<int> pageReadingTimes = []; // Milliseconds per page
  List<bool> rushedPages = []; // Mark if page was read too fast
  int ageGroup = 0;

  // ✅ NEW: Minimum reading time thresholds by age (milliseconds)
  static const Map<int, int> minReadingTimeMs = {
    5: 4000,   // 4 seconds minimum for 5-year-olds
    6: 4000,
    7: 3500,
    8: 3000,
    9: 2500,
    10: 2000,
    11: 1800,
    12: 1600,
  };

  @override
  void initState() {
    super.initState();
    gameStartTime = DateTime.now();
    pageStartTime = DateTime.now();
    startGameTimer();
  }

  void startGameTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameFinished) return;

      setState(() {
        elapsedSeconds++;
      });

      if (elapsedSeconds >= totalGameDuration && !gameFinished) {
        finishStory();
      }
    });
  }

  void onNext() {
    int timeSpent =
        DateTime.now().difference(pageStartTime!).inMilliseconds;

    pageReadingTimes.add(timeSpent);
    
    // ✅ Check if this page was read too fast
    int minTime = minReadingTimeMs[ageGroup] ?? 2000;
    bool isRushed = timeSpent < minTime;
    rushedPages.add(isRushed);

    debugPrint("📖 Page $currentPage read in ${timeSpent}ms (Min: ${minTime}ms) - ${isRushed ? '🚨 RUSHED' : '✅ OK'}");

    goToNextPage();
  }

  void goToNextPage() {
    if (currentPage < storyPages.length - 1) {
      setState(() {
        currentPage++;
        pageStartTime = DateTime.now();
      });
    } else {
      finishStory();
    }
  }

  void finishStory() {
    if (gameFinished) return;
    gameFinished = true;

    gameTimer.cancel();

    double avgReadTime = pageReadingTimes.isEmpty
        ? 0
        : pageReadingTimes.reduce((a, b) => a + b) / pageReadingTimes.length;

    // ✅ Count rushed pages
    int rushedCount = rushedPages.where((r) => r).length;
    double rushRate = storyPages.length > 0 ? rushedCount / storyPages.length : 0;

    StoryGameResult result = StoryGameResult(
      pagesRead: currentPage + 1,
      pagesSkipped: storyPages.length - (currentPage + 1),
      pageReadingTimes: pageReadingTimes,
      avgReadTime: avgReadTime,
      skipRate: rushRate, // ✅ REPURPOSED: Now tracks rush rate (insufficient reading time)
      startTime: gameStartTime,
      endTime: DateTime.now(),
      ageGroup: ageGroup,
    );

    debugPrint("🏁 STORY GAME FINISHED - Rush rate: ${(rushRate*100).toStringAsFixed(1)}%");
    
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
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text("📖 Story Time"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Timer display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "⏱️ Time Remaining",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Text(
                    "$minutes:${seconds.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Story page display
            Expanded(
              child: Center(
                child: Text(
                  storyPages[currentPage],
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Page counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Page ${currentPage + 1} / ${storyPages.length}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ ONLY NEXT BUTTON (Skip removed)
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              ),
              child: const Text("NEXT",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
