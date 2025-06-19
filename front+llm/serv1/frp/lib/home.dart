import 'package:flutter/material.dart';

import 'quest_log_page.dart';
import 'training_programs_page.dart';
import 'auth/profile_page.dart';
import './chat.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Стартовая вкладка: Training

  final List<Widget> _pages = const [
    QuestLogPage(),
    TrainingProgramsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        _pages[_selectedIndex],
        Positioned(
          bottom: 70, // чуть выше нижнего навбара
          right: 20, // отступ от правого края
          child: FloatingActionButton(
            onPressed: () {
              // Перейти на ChatPage
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.chat_bubble_outline),
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: 'Quest Log',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Train',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
}
