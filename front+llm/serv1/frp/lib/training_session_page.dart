import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'training_programs_page.dart';

class TrainingSessionPage extends StatefulWidget {
  final TrainingProgram program;
  const TrainingSessionPage({required this.program, Key? key}) : super(key: key);

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final exercise = widget.program.exercises[current];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name.toLowerCase(),
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Номер и название
            Text(
              '${current + 1}.  ${exercise.title}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),

            // Картинка
            Image.network(exercise.image, height: 200),
            const SizedBox(height: 20),

            // Индикаторы
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.program.exercises.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: i <= current ? Colors.orange : Colors.white,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Альтернатива (заглушка для всех одинаковая)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                exercise.description ?? 'No description available.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),

            // Кнопка "next"
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleNext,
                child: const Text('Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0))),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
  if (current < widget.program.exercises.length - 1) {
    setState(() => current++);
  } else {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseDatabase.instance.ref('users/$uid');

    // Получим текущие XP и уровень
    final snap = await userRef.get();
    final data = snap.value as Map? ?? {};
    final currentCount = data['trainingsCompleted'] ?? 0;
    final newCount = currentCount + 1;

    int xp = (data['xp'] ?? 0) as int;
    int level = (data['level'] ?? 1) as int;

    // Добавляем 50 XP
    xp += 50;

    // Проверка на повышение уровня
    int nextLevelXP = level * 50;
    while (xp >= nextLevelXP) {
      xp -= nextLevelXP;
      level++;
      nextLevelXP = level * 50;
    }

    // Обновим данные в Firebase
    await userRef.update({
      'lastTraining': widget.program.id,
      'xp': xp,
      'level': level,
      'trainingsCompleted': newCount
    });

    // Обновим дату в тренировке
    await FirebaseDatabase.instance
        .ref('trainings/${widget.program.id}/lastCompleted/$uid')
        .set(DateTime.now().toIso8601String());

    if (mounted) Navigator.pop(context);
  }
}
}
