import 'package:flutter/material.dart';
import 'assessment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GameCard> games = [
    GameCard(
      title: "Step Sequencing",
      description: "Memorize and arrange steps in the correct order.",
      icon: Icons.list_rounded,
      imagePath: 'assets/images/step_sequencing.png',
      gameId: 'step_builder',
    ),
    GameCard(
      title: "Story Reading",
      description: "Read and comprehend a story at your own pace.",
      icon: Icons.book,
      imagePath: 'assets/images/story_reading.png',
      gameId: 'story_reading',
    ),
    GameCard(
      title: "Reaction Time",
      description: "Test your focus and response to visual stimuli.",
      icon: Icons.flash_on,
      imagePath: 'assets/images/reaction_time.png',
      gameId: 'reaction_time',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 40),
              _buildTitleSection(),
              const SizedBox(height: 40),
              _buildStartButton(),
              const SizedBox(height: 60),
              _buildGameCardsSection(isWide),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────── TOP BAR ─────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back arrow + Logo
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.black54, size: 24),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D5DF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MindImprint',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Navigation links (for wider screens)
          if (MediaQuery.of(context).size.width > 600)
            Row(
              children: const [
                Text('About', style: TextStyle(color: Colors.black54, fontSize: 13)),
                SizedBox(width: 32),
                Text('Science', style: TextStyle(color: Colors.black54, fontSize: 13)),
                SizedBox(width: 32),
                Text('Contact', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }

  // ───────────── TITLE SECTION ─────────────
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADHD Assessment',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test your cognitive abilities through interactive games.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── START BUTTON ─────────────
  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B6DD6),
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AssessmentFlow(ageGroup: 1),
              ),
            );
          },
          child: const Text(
            'Begin Assessment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── GAME CARDS SECTION ─────────────
  Widget _buildGameCardsSection(bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isWide ? 3 : 1,
          childAspectRatio: isWide ? 0.95 : 1.1,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          return _buildGameCard(games[index]);
        },
      ),
    );
  }

  Widget _buildGameCard(GameCard game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailsScreen(game: game),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image area (top half)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Colors.grey.shade100,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildGameImagePlaceholder(game),
                  ),
                  // Icon badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          game.icon,
                          size: 24,
                          color: const Color(0xFF6D5DF6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content area (bottom half)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D5DF6),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Color(0xFF6D5DF6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build image placeholders
  Widget _buildGameImagePlaceholder(GameCard game) {
    return Image.asset(
      game.imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              game.icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
        );
      },
    );
  }
}

// ───────────── GAME DETAILS SCREEN ─────────────
class GameDetailsScreen extends StatelessWidget {
  final GameCard game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final adhgDetails = _getADHDDetails(game.gameId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ADHD Assessment Details',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Game Image
              Container(
                width: double.infinity,
                height: 240,
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    game.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          game.icon,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    const Text(
                      'About This Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      adhgDetails['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // What It Measures
                    const Text(
                      'What It Measures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildMeasuresList(adhgDetails['measures'] as List<String>? ?? []),
                    const SizedBox(height: 32),
                    // ADHD Insights
                    const Text(
                      'ADHD Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildInsightsList(adhgDetails['insights'] as List<String>? ?? []),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMeasuresList(List<String> measures) {
    return measures
        .map(
          (measure) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D5DF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    measure,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildInsightsList(List<String> insights) {
    return insights
        .map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6D5DF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6D5DF6).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _getADHDDetails(String gameId) {
    final details = {
      'step_builder': {
        'description':
            'This game evaluates your ability to memorize a sequence of steps and then arrange them in the correct order when they are shuffled. It tests working memory, executive function, and planning skills.',
        'measures': [
          'Working Memory: Can you hold and recall the correct sequence?',
          'Executive Function: Can you plan and organize the steps logically?',
          'Cognitive Flexibility: Can you adapt when the order is changed?',
          'Attention to Detail: Do you notice when steps are out of sequence?',
        ],
        'insights': [
          'Strong performance indicates good working memory and organizational skills.',
          'Difficulty with sequence recall may suggest challenges with executive function, common in ADHD.',
          'Frequent errors in ordering may indicate impulsivity or lack of attention to detail.',
          'Slower completion time could suggest careful, methodical thinking or processing delays.',
        ],
      },
      'story_reading': {
        'description':
            'This game measures your reading comprehension and ability to maintain focus while reading. It also tracks reading speed to identify rushing behaviors or sustained attention patterns.',
        'measures': [
          'Reading Comprehension: Do you understand the story content?',
          'Sustained Attention: Can you maintain focus throughout the story?',
          'Reading Pace: Do you rush through or read carefully?',
          'Task Persistence: Do you complete the entire story?',
        ],
        'insights': [
          'Reading too quickly (rushing) can indicate impulsivity, a key ADHD symptom.',
          'Consistent pacing suggests good impulse control and attention regulation.',
          'Difficulty understanding suggests concentration issues or reading comprehension challenges.',
          'Uneven pacing may indicate attention fluctuations typical of ADHD.',
        ],
      },
      'reaction_time': {
        'description':
            'This game evaluates your reaction speed and consistency in responding to visual stimuli. It measures attention, focus, and the ability to maintain consistent performance over time.',
        'measures': [
          'Reaction Speed: How quickly do you respond to stimuli?',
          'Consistency: Are your responses consistent throughout the game?',
          'Attention Focus: Do you maintain focus on the target?',
          'Impulsivity: Do you respond before fully processing the stimulus?',
        ],
        'insights': [
          'Highly variable reaction times may indicate attention regulation difficulties (ADHD trait).',
          'Consistently slow responses might suggest processing delays or reduced arousal.',
          'Fast responses with high accuracy indicate good impulse control and attention.',
          'Erratic performance may reflect fluctuating attention, common in ADHD presentations.',
        ],
      },
    };

    return details[gameId] ?? {'description': '', 'measures': [], 'insights': []};
  }
}

// ───────────── GAME CARD MODEL ─────────────
class GameCard {
  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final String gameId;

  GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.gameId,
  });
}
