// lib/pages/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './auth_service.dart'; // поправьте путь, если у вас другой

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late final DatabaseReference _userRef; // /users/{uid}/ в RTDB
  late final Stream<DatabaseEvent> _userStream; // живой поток данных

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    _userStream = _userRef.onValue;
  }

  int _xpForLevel(int level) => level * 50;

  /* --------------------  Служебные апдейтеры  -------------------- */
  Future<void> _updateField(
    String key,
    String? oldVal, {
    TextInputType inputType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: oldVal ?? '');

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Change $key'),
            content: TextField(
              controller: controller,
              keyboardType: inputType,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    await _userRef.update({key: value});
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _changeDisplayName(String? currentName) async {
    await _updateField('name', currentName);
    final snap = await _userRef.child('name').get();
    await user.updateDisplayName(snap.value?.toString() ?? currentName ?? '');
    setState(() {}); // перерисовать имя на экране
  }

  /* --------------------  Аватар  -------------------- */
  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // загружаем в Storage
    final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.jpg');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    // записываем ссылку в Auth и RTDB
    await user.updatePhotoURL(url);
    await _userRef.update({'avatar': url});

    if (mounted) setState(() {}); // перерисовать виджет Icon/NetworkImage
  }

  /* --------------------  Выход  -------------------- */
  Future<void> _signOut() => AuthService().signOut();

  /* --------------------  UI  -------------------- */
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _userStream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        final data =
            (snapshot.data?.snapshot.value ?? {}) as Map<Object?, Object?>;
        final name = data['name']?.toString() ?? user.displayName ?? 'Name';
        final weight = data['weight']?.toString() ?? '––';
        final height = data['height']?.toString() ?? '––';
        final xp = int.tryParse(data['xp']?.toString() ?? '') ?? 0;
        final level = int.tryParse(data['level']?.toString() ?? '') ?? 1;
        final photo = data['avatar']?.toString() ?? user.photoURL;
        final trainingsCompleted =
            int.tryParse(data['trainingsCompleted']?.toString() ?? '0') ?? 0;

        // Сколько XP требуется на текущий уровень
        final need = _xpForLevel(level); // level * 50

        // Столько набрано в рамках именно этого уровня
        final gainedThisLevel = xp % need;

        // Прогресс от 0.0 до 1.0, NaN/Infinity исключены
        final progress =
            need == 0 ? 0.0 : (gainedThisLevel / need).clamp(0.0, 1.0);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              PopupMenuButton(
                onSelected: (_) => _signOut(),
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(value: 'signout', child: Text('Sign out')),
                    ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _changeAvatar,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child:
                        photo == null
                            ? const Icon(Icons.account_circle, size: 80)
                            : null,
                  ),
                ),
                const SizedBox(height: 8),

                /* ----------  Имя  ---------- */
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _changeDisplayName(name),
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /* ----------  XP-Progress  ---------- */
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 20,
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          const Color.fromARGB(255, 0, 170, 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp / ${_xpForLevel(level)} xp',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$level level', style: const TextStyle(fontSize: 16)),
                    Text(
                      '${level + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /* ----------  Вес и рост, кликабельные  ---------- */
                _dataTile(
                  'Weight',
                  weight,
                  () => _updateField(
                    'weight',
                    weight,
                    inputType: TextInputType.number,
                  ),
                ),
                _dataTile(
                  'Height',
                  height,
                  () => _updateField(
                    'height',
                    height,
                    inputType: TextInputType.number,
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Your progress:\n$trainingsCompleted trainings completed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.orange),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dataTile(String title, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.arrow_upward, size: 18, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
