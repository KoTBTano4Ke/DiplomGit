import 'package:flutter/material.dart';

class QuestLogPage extends StatelessWidget {
  const QuestLogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Log'),
      ),
      body: const Center(
        child: Text(
          'Your completed and active workout quests will appear here.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
