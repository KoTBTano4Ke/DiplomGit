import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TrainingProgramsPage(),
    );
  }
}

class TrainingProgramsPage extends StatelessWidget {
  final List<Map<String, dynamic>> programs = [
    {"title": "back training", "image": "assets/back.png"},
    {"title": "arms training", "image": "assets/arms.png"},
    {"title": "legs training", "image": "assets/legs.png"},
    {"title": "abs training", "image": "assets/abs.jpg"},
  ];

  void _showExerciseDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$title Plan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("- Exercise 1\n- Exercise 2\n- Exercise 3"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Start"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Training programs", style: TextStyle(color: Colors.orange[800])),
        backgroundColor: Colors.white,
        actions: [Icon(Icons.settings, color: Colors.black)],
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recommended:", style: TextStyle(fontSize: 20, color: Colors.orange[800], fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: programs.map((program) {
                  return GestureDetector(
                    onTap: () => _showExerciseDialog(context, program['title']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: Offset(2, 4)),
                        ],
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Image.asset(program['image'], fit: BoxFit.contain)),
                          SizedBox(height: 8),
                          Text(program['title'], style: TextStyle(fontSize: 16)),
                          Icon(Icons.arrow_forward, color: Colors.orange),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage())),
        backgroundColor: Colors.orange,
        child: Icon(Icons.chat_bubble_outline),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Quest Log'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center, color: Colors.orange), label: 'Train'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        backgroundColor: Colors.orange,
      ),
      body: Center(child: Text("Chat is under development.")),
    );
  }
}
