import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(userInput, true));
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.96:5001/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': userInput}),
      );

      final responseData = json.decode(response.body);
      final reply = responseData['response'] ?? 'Ошибка ответа';

      setState(() {
        _messages.add(_ChatMessage(reply, false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage('Ошибка подключения к серверу.', false));
      });
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
