import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late final DatabaseReference _chatRef;

  @override
  void initState() {
    super.initState();
    _chatRef = FirebaseDatabase.instance.ref('users/$_uid/chatHistory');
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final snapshot = await _chatRef.orderByKey().get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final loaded = data.entries.map((entry) {
        final msg = entry.value as Map;
        return _ChatMessage(
          msg['message'],
          msg['sender'] == 'user',
        );
      }).toList();
      setState(() => _messages.addAll(loaded));
    }
  }

  Future<void> _saveMessage(String text, bool isUser) async {
    final msg = {
      'message': text,
      'sender': isUser ? 'user' : 'bot',
    };
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _chatRef.child(timestamp).set(msg);
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(userInput, true));
    });
    _controller.clear();
    await _saveMessage(userInput, true);

    try {
      final response = await http.post(
        Uri.parse('http://10.244.168.176:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': userInput}),
      );
      final responseData = json.decode(response.body);
      final reply = responseData['response'] ?? 'Ошибка ответа';

      setState(() {
        _messages.add(_ChatMessage(reply, false));
      });
      await _saveMessage(reply, false);
    } catch (e) {
      const errorText = 'Ошибка подключения к серверу.';
      setState(() {
        _messages.add(_ChatMessage(errorText, false));
      });
      await _saveMessage(errorText, false);
    }
  }

  TextSpan _formatText(String text) {
    final List<InlineSpan> spans = [];

    final regex = RegExp(r'(\*\*.*?\*\*|\*.*?\*|".*?")|([^\*""]+)');
    for (final match in regex.allMatches(text)) {
      final part = match.group(0)!;
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(TextSpan(
            text: part.substring(2, part.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (part.startsWith('*') && part.endsWith('*')) {
        spans.add(TextSpan(
            text: part.substring(1, part.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (part.startsWith('"') && part.endsWith('"')) {
        spans.add(TextSpan(
            text: part,
            style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: part));
      }
    }

    return TextSpan(style: const TextStyle(color: Colors.black), children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("WeiderGPT", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.orange[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: RichText(text: _formatText(msg.text)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}
