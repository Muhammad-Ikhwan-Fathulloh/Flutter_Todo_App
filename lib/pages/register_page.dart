import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_cubit.dart';
import 'todo_page.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            ElevatedButton(
              onPressed: () async {
                await context.read<AuthCubit>().register(
                      nameCtrl.text,
                      emailCtrl.text,
                      passCtrl.text,
                    );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => TodoPage()),
                );
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}