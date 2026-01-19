import 'dart:convert';

// ════════════════════════════════════════════════════════════════
// ✅ WAIT FOR YOUR TURN GAME METRICS
// ════════════════════════════════════════════════════════════════
class WaitingGameResult {
  final int prematureTaps;
  final List<int> reactionTimes;
  final double avgReaction;
  final double reactionVariability;
  final int totalTrials;
  final DateTime startTime;
  final DateTime endTime;
  final int ageGroup;

  WaitingGameResult({
    required this.prematureTaps,
    required this.reactionTimes,
    required this.avgReaction,
    required this.reactionVariability,
    required this.totalTrials,
    required this.startTime,
    required this.endTime,
    required this.ageGroup,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      "game_id": "wait_for_your_turn",
      "age_group": ageGroup,
      "premature_taps": prematureTaps,
      "reaction_times": reactionTimes,
      "avg_reaction": avgReaction,
      "reaction_variability": reactionVariability,
      "total_trials": totalTrials,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "duration_seconds": endTime.difference(startTime).inSeconds,
    };
  }
}

// ════════════════════════════════════════════════════════════════
// ✅ STORY READING GAME METRICS
// ════════════════════════════════════════════════════════════════
class StoryGameResult {
  final int pagesRead;
  final int pagesSkipped;
  final List<int> pageReadingTimes;
  final double avgReadTime;
  final double skipRate;
  final DateTime startTime;
  final DateTime endTime;
  final int ageGroup;

  StoryGameResult({
    required this.pagesRead,
    required this.pagesSkipped,
    required this.pageReadingTimes,
    required this.avgReadTime,
    required this.skipRate,
    required this.startTime,
    required this.endTime,
    required this.ageGroup,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      "game_id": "story_reading",
      "age_group": ageGroup,
      "pages_read": pagesRead,
      "pages_skipped": pagesSkipped,
      "page_reading_times": pageReadingTimes,
      "avg_read_time": avgReadTime,
      "skip_rate": skipRate,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "duration_seconds": endTime.difference(startTime).inSeconds,
    };
  }
}

// ════════════════════════════════════════════════════════════════
// ✅ STEP BUILDER GAME METRICS
// ════════════════════════════════════════════════════════════════
class StepGameResult {
  final int stepsSkipped;
  final int orderErrors;
  final bool taskCompleted;
  final List<int> stepPlacementTimes; // Time to place each step
  final DateTime startTime;
  final DateTime endTime;
  final int ageGroup;

  StepGameResult({
    required this.stepsSkipped,
    required this.orderErrors,
    required this.taskCompleted,
    required this.stepPlacementTimes,
    required this.startTime,
    required this.endTime,
    required this.ageGroup,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      "game_id": "step_builder",
      "age_group": ageGroup,
      "steps_skipped": stepsSkipped,
      "order_errors": orderErrors,
      "task_completed": taskCompleted,
      "step_placement_times": stepPlacementTimes,
      "avg_placement_time": stepPlacementTimes.isEmpty
          ? 0
          : stepPlacementTimes.reduce((a, b) => a + b) / stepPlacementTimes.length,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "duration_seconds": endTime.difference(startTime).inSeconds,
    };
  }
}

// ════════════════════════════════════════════════════════════════
// ✅ FIND THE STAR GAME METRICS
// ════════════════════════════════════════════════════════════════
class FindStarGameResult {
  final int starsFound;
  final int totalMisclicks;
  final List<int> timesPerStar;
  final double avgTimePerStar;
  final DateTime startTime;
  final DateTime endTime;
  final int ageGroup;

  FindStarGameResult({
    required this.starsFound,
    required this.totalMisclicks,
    required this.timesPerStar,
    required this.avgTimePerStar,
    required this.startTime,
    required this.endTime,
    required this.ageGroup,
  });

  // Convert to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      "game_id": "find_the_star",
      "age_group": ageGroup,
      "stars_found": starsFound,
      "total_misclicks": totalMisclicks,
      "times_per_star": timesPerStar,
      "avg_time_per_star": avgTimePerStar,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "duration_seconds": endTime.difference(startTime).inSeconds,
    };
  }
}

// ════════════════════════════════════════════════════════════════
// ✅ COMPLETE SESSION RESULT (All games)
// ════════════════════════════════════════════════════════════════
class AssessmentSessionResult {
  final WaitingGameResult waitingResult;
  final StoryGameResult storyResult;
  final StepGameResult stepResult;
  final FindStarGameResult? findStarResult;
  final int ageGroup;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  AssessmentSessionResult({
    required this.waitingResult,
    required this.storyResult,
    required this.stepResult,
    this.findStarResult,
    required this.ageGroup,
    required this.sessionStart,
    required this.sessionEnd,
  });

  // Convert complete session to JSON for backend
  Map<String, dynamic> toJson() {
    return {
      "session_id": sessionStart.millisecondsSinceEpoch.toString(),
      "age_group": ageGroup,
      "session_start": sessionStart.toIso8601String(),
      "session_end": sessionEnd.toIso8601String(),
      "total_duration_seconds": sessionEnd.difference(sessionStart).inSeconds,
      "wait_for_your_turn": waitingResult.toJson(),
      "story_reading": storyResult.toJson(),
      "step_builder": stepResult.toJson(),
      if (findStarResult != null) "find_the_star": findStarResult!.toJson(),
    };
  }

  // Serialize to JSON string for sending to backend
  String toJsonString() => jsonEncode(toJson());
}
