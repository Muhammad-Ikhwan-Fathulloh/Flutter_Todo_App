import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../models/todo_model.dart';

class TodoCubit extends Cubit<List<Todo>> {
  TodoCubit() : super([]);

  Future<void> fetchTodos(String userId) async {
    final response = await http.get(Uri.parse(
        "https://694033c6993d68afba6b507c.mockapi.io/users/$userId/todo"));

    final List data = jsonDecode(response.body);
    emit(data.map((e) => Todo.fromJson(e)).toList());
  }

  Future<void> addTodo(
      String userId, String title, String desc) async {
    await http.post(
      Uri.parse(
          "https://694033c6993d68afba6b507c.mockapi.io/users/$userId/todo"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title,
        "description": desc,
        "status": false,
        "userId": userId,
      }),
    );
    fetchTodos(userId);
  }

  Future<void> updateTodo(String userId, Todo todo) async {
    await http.put(
      Uri.parse(
          "https://694033c6993d68afba6b507c.mockapi.io/users/$userId/todo/${todo.id}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": todo.title,
        "description": todo.description,
        "status": !todo.status,
      }),
    );
    fetchTodos(userId);
  }

  Future<void> deleteTodo(String userId, String todoId) async {
    await http.delete(Uri.parse(
        "https://694033c6993d68afba6b507c.mockapi.io/users/$userId/todo/$todoId"));
    fetchTodos(userId);
  }
}