import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/todo_cubit.dart';
import '../models/todo_model.dart';
import 'login_page.dart';

class TodoPage extends StatelessWidget {
  TodoPage({super.key});

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state!;
    context.read<TodoCubit>().fetchTodos(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text("Todo - ${user.name}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: "Title")),
          TextField(controller: descCtrl, decoration: const InputDecoration(hintText: "Description")),
          ElevatedButton(
            onPressed: () {
              context.read<TodoCubit>().addTodo(
                    user.id,
                    titleCtrl.text,
                    descCtrl.text,
                  );
            },
            child: const Text("Add Todo"),
          ),
          Expanded(
            child: BlocBuilder<TodoCubit, List<Todo>>(
              builder: (_, todos) {
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (_, i) {
                    final Todo todo = todos[i];
                    return ListTile(
                      title: Text(todo.title),
                      subtitle: Text(todo.description),
                      leading: Checkbox(
                        value: todo.status,
                        onChanged: (_) {
                          context.read<TodoCubit>().updateTodo(user.id, todo);
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<TodoCubit>().deleteTodo(user.id, todo.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}