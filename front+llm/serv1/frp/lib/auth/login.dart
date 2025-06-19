import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 60),
          Image.asset('assets/weight_picked 1.png', height: 60),
          Text('FitnessRolePlay', 
          style: TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'email:', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'password:', border: OutlineInputBorder()),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("forgot password?", style: TextStyle(color: Color.fromARGB(255, 189, 101, 0))),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () async {
                    try {
                      await AuthService().registerWithEmail(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );
                    } catch (e) {
                      _showError("Ошибка входа: $e");
                    }
                  },
                  child: const Text("Log in", style: TextStyle(fontSize: 18, color: Colors.black)),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 247, 177, 73),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () async {
                      try {
                        await AuthService().signInWithEmail(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );
                      } catch (e) {
                        _showError("Ошибка входа: $e");
                      }
                    },
                    child: const Text("Register", style: TextStyle(fontSize: 18, color: Colors.black)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(thickness: 1),
                ),
                ElevatedButton.icon(
                  icon: Image.asset('assets/logo_google.png', height: 24),
                  label: const Text("Log in with google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () async {
                    try {
                      await AuthService().signInWithGoogle();
                    } catch (e) {
                      _showError("Ошибка Google входа: $e");
                    }
                  },
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
