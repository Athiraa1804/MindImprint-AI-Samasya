import 'package:flutter/material.dart';
import 'dart:html' as html show AudioElement;

class CompletionScreen extends StatefulWidget {
  final Map<String, dynamic> cognitiveProfile;

  const CompletionScreen({
    super.key,
    required this.cognitiveProfile,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  late html.AudioElement audioElement;
  bool isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    audioElement = html.AudioElement('assets/sounds/completion_chime.mp3');
    audioElement.onEnded.listen((_) {
      if (mounted) {
        setState(() => isAudioPlaying = false);
      }
    });
    _playCompletionAudio();
  }

  @override
  void dispose() {
    audioElement.pause();
    super.dispose();
  }

  Future<void> _playCompletionAudio() async {
    try {
      audioElement.play();
      setState(() => isAudioPlaying = true);
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Assessment Complete! 🎉"),
        elevation: 0,
        centerTitle: true,
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎵 Audio Player Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🎵 Completion Sound',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAudioPlaying
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAudioPlaying ? '🔊 Playing' : '⏸ Idle',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAudioPlaying
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _playCompletionAudio,
                          icon: const Icon(Icons.replay_circle_filled),
                          label: const Text('Replay Sound'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 🧠 AI COGNITIVE PROFILE
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
                if (widget.cognitiveProfile['overall_score'] != null)
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
                          "${(widget.cognitiveProfile['overall_score'] * 100).toStringAsFixed(1)}% (${widget.cognitiveProfile['overall_level'] ?? 'N/A'})",
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
                if (widget.cognitiveProfile['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "⚡ Impulsivity",
                    Colors.red,
                    widget.cognitiveProfile['cognitive_profile']['impulsivity'],
                  ),

                const SizedBox(height: 12),

                // Domain 2: Attention
                if (widget.cognitiveProfile['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "👀 Attention",
                    Colors.blue,
                    widget.cognitiveProfile['cognitive_profile']['attention'],
                  ),

                const SizedBox(height: 12),

                // Domain 3: Memory/Organization
                if (widget.cognitiveProfile['cognitive_profile'] != null)
                  _buildCognitiveDomainCard(
                    "🧠 Memory & Organization",
                    Colors.teal,
                    widget.cognitiveProfile['cognitive_profile']['memory_organization'],
                  ),

                // Recommendation
                if (widget.cognitiveProfile['recommendation'] != null)
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
                              widget.cognitiveProfile['recommendation'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Saved Message
                Center(
                  child: Text(
                    "✅ All data has been saved successfully!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCognitiveDomainCard(
      String title, Color color, dynamic domainData) {
    if (domainData == null) {
      return const SizedBox.shrink();
    }

    final score = (domainData is Map) ? domainData['score'] ?? 0 : 0;
    final level = (domainData is Map) ? domainData['level'] ?? 'N/A' : 'N/A';
    final conclusion =
        (domainData is Map) ? domainData['conclusion'] ?? '' : '';
    final evidence =
        (domainData is Map && domainData['evidence'] is List)
            ? List<String>.from(domainData['evidence'])
            : [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
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
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(score * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Level: $level",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            conclusion,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...evidence.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "• $e",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
