// lib/pages/training_programs_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './training_session_page.dart';

class TrainingProgram {
  final String id;                // legs, arms, …
  final String name;              // Legs Training
  final List<Exercise> exercises; // 3 элемента
  TrainingProgram({required this.id, required this.name, required this.exercises});

  factory TrainingProgram.fromMap(String id, Map data) => TrainingProgram(
    id: id,
    name: data['name'] ?? id,
    exercises: (data['exercises'] as List)
        .map((e) => Exercise(title: e['title'], image: e['image'], description: e['description']))
        .toList(),
  );
}

class Exercise {
  final String title;
  final String image;
  final String description;
  Exercise({required this.title, required this.image, required this.description});
}

class TrainingProgramsPage extends StatefulWidget {
  const TrainingProgramsPage({Key? key}) : super(key: key);
  @override
  State<TrainingProgramsPage> createState() => _TrainingProgramsPageState();
}

class _TrainingProgramsPageState extends State<TrainingProgramsPage> {
  late Future<_PageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchData();
  }

  Future<_PageData> _fetchData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
  final userSnap = await FirebaseDatabase.instance.ref('users/$uid/lastTraining').get();
  final lastId = userSnap.value as String?;
    // 1) Firebase и SharedPreferences
    await Firebase.initializeApp();

    // 2) Загружаем все программы
    final snap = await FirebaseDatabase.instance.ref('trainings').get();
    final all = snap.children
        .map((c) => TrainingProgram.fromMap(c.key!, c.value as Map))
        .toList();

    // 3) Последняя тренировка
    final last = all.firstWhere(
      (t) => t.id == lastId,
      orElse: () => all.first, // если ещё ничего не делали
    );

    // 4) Recommendation: случайные 2, не совпадающие с last
    final recPool = [...all]..removeWhere((t) => t.id == last.id);
    recPool.shuffle(Random());
    final recommended = recPool.take(2).toList();

    return _PageData(allPrograms: all, last: last, recommended: recommended);
  }

  // =========== UI ===========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training programs')),
      body: FutureBuilder<_PageData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Last training ----------
                const _SectionTitle('Last training:'),
                _TrainingCard(program: data.last, onTap: _onTapProgram),

                const SizedBox(height: 20),

                // ---------- Recommended ----------
                const _SectionTitle('Recommended:'),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: data.recommended.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 4 / 3,
                  ),
                  itemBuilder: (_, i) =>
                      _TrainingCard(program: data.recommended[i], onTap: _onTapProgram),
                ),

                const SizedBox(height: 20),

                // ---------- All programs ----------
                const _SectionTitle('All programs:'),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: data.allPrograms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 4 / 3,
                  ),
                  itemBuilder: (_, i) =>
                      _TrainingCard(program: data.allPrograms[i], onTap: _onTapProgram),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Диалог и завершение ----------
  void _onTapProgram(TrainingProgram program) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(program.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: program.exercises
              .map((e) => ListTile(
                    leading: Image.network(e.image, width: 40, height: 40),
                    title: Text(e.title),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // закрыть диалог

              await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainingSessionPage(program: program),
              ),
            );
            setState(() {
            _future = _fetchData();
            });

            },
            child: const Text('Start',
            style: TextStyle(
              color: Colors.black
            ),),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final TrainingProgram program;
  final void Function(TrainingProgram) onTap;
  const _TrainingCard({required this.program, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(program),
      child: Card(
        elevation: 4,
        color: const Color(0xFFFFF2E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Image.network(program.exercises.first.image, height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(program.name, style: const TextStyle(fontSize: 14))),
                  const Icon(Icons.arrow_forward, color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
      );
}

class _PageData {
  final List<TrainingProgram> allPrograms;
  final TrainingProgram last;
  final List<TrainingProgram> recommended;
  _PageData(
      {required this.allPrograms,
      required this.last,
      required this.recommended});
}
