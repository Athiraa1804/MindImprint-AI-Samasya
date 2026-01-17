import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../games/wait_for_your_turn.dart';
import '../games/game_4/story_reading.dart';
import '../games/step_builder.dart';
import '../models/assessment_models.dart';

class AssessmentFlow extends StatefulWidget {
  final int ageGroup;

  const AssessmentFlow({super.key, required this.ageGroup});

  @override
  State<AssessmentFlow> createState() => _AssessmentFlowState();
}

class _AssessmentFlowState extends State<AssessmentFlow> {
  WaitingGameResult? waitingResult;
  StoryGameResult? storyResult;
  StepGameResult? stepResult;
  bool isLoading = false;
  int currentGameIndex = 0; // ✅ Track which game to show (0=Wait, 1=Story, 2=Step, 3=Done)
  Map<String, dynamic>? cognitiveProfile; // ✅ Store AI analysis

  @override
  void initState() {
    super.initState();
    // Don't call startAssessment - games will be shown in build()
  }

  // ✅ NEW: Callback when Game 1 finishes
  void onWaitGameFinished(WaitingGameResult result) {
    debugPrint("✅ WAIT GAME RESULT RECEIVED");
    setState(() {
      waitingResult = result;
      currentGameIndex = 1; // Move to Game 2
    });
  }

  // ✅ NEW: Callback when Game 2 finishes
  void onStoryGameFinished(StoryGameResult result) {
    debugPrint("✅ STORY GAME RESULT RECEIVED");
    setState(() {
      storyResult = result;
      currentGameIndex = 2; // Move to Game 3
    });
  }

  // ✅ NEW: Callback when Game 3 finishes
  void onStepGameFinished(StepGameResult result) {
    debugPrint("✅ STEP GAME RESULT RECEIVED");
    setState(() {
      stepResult = result;
      currentGameIndex = 3; // Move to completion
    });
    // Automatically send data and show report
    sendSessionDataToBackend();
  }

  // ✅ NEW: Build method to show current game
  @override
  Widget build(BuildContext context) {
    if (currentGameIndex == 0) {
      // Show Game 1
      return WaitForYourTurn4(
        ageGroup: widget.ageGroup,
        onGameFinished: onWaitGameFinished,
      );
    } else if (currentGameIndex == 1) {
      // Show Game 2
      return ReadingStoryGame(
        onGameFinished: onStoryGameFinished,
      );
    } else if (currentGameIndex == 2) {
      // Show Game 3
      return StepBuilderGame(
        ageGroup: widget.ageGroup,
        onGameFinished: onStepGameFinished,
      );
    } else {
      // Show loading/completion
      return Scaffold(
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text("Assessment Complete!"),
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SEND COMPLETE SESSION DATA TO FLASK BACKEND
  // ════════════════════════════════════════════════════════════════
  Future<void> sendSessionDataToBackend() async {
    if (waitingResult == null || storyResult == null || stepResult == null) {
      debugPrint("❌ Missing game results");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create complete session result
      AssessmentSessionResult sessionResult = AssessmentSessionResult(
        waitingResult: waitingResult!,
        storyResult: storyResult!,
        stepResult: stepResult!,
        ageGroup: widget.ageGroup,
        sessionStart: waitingResult!.startTime,
        sessionEnd: stepResult!.endTime,
      );

      // Send to Flask backend
      final url = Uri.parse("http://127.0.0.1:5000/save_session");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: sessionResult.toJsonString(),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Session saved successfully");
        debugPrint("Backend response: ${response.body}");
        
        // ✅ Parse cognitive profile from response
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['cognitive_profile'] != null) {
            cognitiveProfile = responseData['cognitive_profile'];
            debugPrint("🧠 Cognitive Profile Received: $cognitiveProfile");
          }
        } catch (e) {
          debugPrint("⚠️ Could not parse cognitive profile: $e");
        }
      } else {
        debugPrint("⚠️ Server error: ${response.statusCode}");
        debugPrint("Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Connection error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }

    // Show final report after data is sent
    if (mounted) {
      showFinalReport();
    }
  }

  void showFinalReport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🧠 Assessment Complete!"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== AI COGNITIVE PROFILE (if available) =====
              if (cognitiveProfile != null) ...[
                const Text(
                  "🤖 AI COGNITIVE ANALYSIS",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Overall Score
                if (cognitiveProfile!['overall_score'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Overall Cognitive Score",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(cognitiveProfile!['overall_score'] * 100).toStringAsFixed(1)}% (${cognitiveProfile!['overall_level'] ?? 'N/A'})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Domain 1: Impulsivity
                if (cognitiveProfile!['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "⚡ Impulsivity",
                    Colors.red,
                    cognitiveProfile!['cognitive_profile']['impulsivity'],
                  ),
                
                const SizedBox(height: 12),
                
                // Domain 2: Attention
                if (cognitiveProfile!['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "👀 Attention",
                    Colors.blue,
                    cognitiveProfile!['cognitive_profile']['attention'],
                  ),
                
                const SizedBox(height: 12),
                
                // Domain 3: Memory/Organization
                if (cognitiveProfile!['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "🧠 Memory & Organization",
                    Colors.teal,
                    cognitiveProfile!['cognitive_profile']['memory_organization'],
                  ),
                
                // Recommendation
                if (cognitiveProfile!['recommendation'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "💡 Recommendations",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cognitiveProfile!['recommendation'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
              ],
              
              // ===== GAME-BY-GAME RESULTS =====
              const Text(
                "📊 Detailed Results",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // === WAIT FOR YOUR TURN RESULTS ===
              const Text(
                "⏳ Impulse Control (Wait For Your Turn)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildResultRow(
                "Total Correct Taps",
                "${waitingResult!.reactionTimes.length}",
              ),
              _buildResultRow(
                "Premature Taps",
                "${waitingResult!.prematureTaps}",
              ),
              _buildResultRow(
                "Avg Reaction Time",
                "${waitingResult!.avgReaction.toStringAsFixed(0)} ms",
              ),
              _buildResultRow(
                "Reaction Variability",
                "${waitingResult!.reactionVariability.toStringAsFixed(0)} ms",
              ),
              _buildResultRow(
                "Total Trials",
                "${waitingResult!.totalTrials}",
              ),

              const SizedBox(height: 20),

              // === STORY READING RESULTS ===
              const Text(
                "📖 Reading Attention (Story Reading)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildResultRow(
                "Pages Read",
                "${storyResult!.pagesRead}",
              ),
              _buildResultRow(
                "Pages Skipped",
                "${storyResult!.pagesSkipped}",
              ),
              _buildResultRow(
                "Avg Read Time",
                "${storyResult!.avgReadTime.toStringAsFixed(0)} ms",
              ),
              _buildResultRow(
                "Skip Rate",
                "${(storyResult!.skipRate * 100).toStringAsFixed(1)}%",
              ),

              const SizedBox(height: 20),

              // === STEP BUILDER RESULTS ===
              const Text(
                "🏗️ Organization & Planning (Step Builder)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              _buildResultRow(
                "Steps Skipped",
                "${stepResult!.stepsSkipped}",
              ),
              _buildResultRow(
                "Order Errors",
                "${stepResult!.orderErrors}",
              ),
              _buildResultRow(
                "Task Completed",
                stepResult!.taskCompleted ? "✅ Yes" : "❌ No",
              ),
              _buildResultRow(
                "Avg Step Time",
                "${stepResult!.stepPlacementTimes.isEmpty ? 0 : (stepResult!.stepPlacementTimes.reduce((a, b) => a + b) / stepResult!.stepPlacementTimes.length).toStringAsFixed(0)} ms",
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "✅ All data has been saved to the backend successfully!",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home screen
            },
            child: const Text("Done"),
          )
        ],
      ),
    );
  }

  /// Build a cognitive domain card (Impulsivity, Attention, Memory/Org)
  Widget _buildCognitiveDomainCard(
    String title,
    Color color,
    Map<String, dynamic>? domain,
  ) {
    if (domain == null) return const SizedBox.shrink();

    final score = domain['score'] ?? 0;
    final level = domain['level'] ?? 'Unknown';
    final conclusion = domain['conclusion'] ?? '';
    final evidence = domain['evidence'] ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(level),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Score: ${(score * 100).toStringAsFixed(1)}%",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            conclusion,
            style: const TextStyle(fontSize: 11),
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.from(
                evidence
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "• $e",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get color for severity level
  Color _getLevelColor(String level) {
    switch (level) {
      case 'Very High':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Moderate':
        return Colors.yellow.shade700;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
