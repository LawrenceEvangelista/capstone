import 'package:flutter/material.dart';

class QuizNav extends StatefulWidget {
  const QuizNav({super.key});

  @override
  State<QuizNav> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizNav> {
  int? _selectedIndex; // track selected option

  final List<String> options = [
    'A. Tinulungan niya itong mag-araro.',
    'B. Tumakbo siya palayo.',
    'C. Natulog lang siya.',
    'D. Kumain ng damo.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Quiz'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ang Mabait na Kalabaw',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Question
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '1. Ano ang ginawa ng kalabaw upang matulungan ang magsasaka?',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),

            // Clickable Options
            for (int index = 0; index < options.length; index++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _selectedIndex == index
                            ? Colors.yellow.shade100
                            : Colors.white,
                    border: Border.all(
                      color:
                          _selectedIndex == index ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    options[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
