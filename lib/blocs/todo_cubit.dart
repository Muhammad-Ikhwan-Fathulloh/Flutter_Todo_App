import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_sqlite/database/database_helper.dart';
import 'package:todo_sqlite/models/todo_model.dart';

part 'todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  TodoCubit() : super(TodoInitial());

  Future<void> fetchTodos(int userId, {String filter = 'all'}) async {
    emit(TodoLoading());
    
    try {
      final todos = await DatabaseHelper.instance.getTodosByUser(userId, filter: filter);
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError('Failed to load todos: ${e.toString()}'));
    }
  }

  Future<void> addTodo(Todo todo) async {
    try {
      emit(TodoLoading());
      
      final id = await DatabaseHelper.instance.createTodo(todo);
      final newTodo = todo.copyWith(id: id);
      
      final currentState = state;
      if (currentState is TodoLoaded) {
        emit(TodoLoaded([newTodo, ...currentState.todos]));
      }
    } catch (e) {
      emit(TodoError('Failed to add todo: ${e.toString()}'));
    }
  }

  Future<void> updateTodo(Todo todo) async {
    try {
      await DatabaseHelper.instance.updateTodo(todo);
      
      final currentState = state;
      if (currentState is TodoLoaded) {
        final todos = currentState.todos.map((t) => t.id == todo.id ? todo : t).toList();
        emit(TodoLoaded(todos));
      }
    } catch (e) {
      emit(TodoError('Failed to update todo: ${e.toString()}'));
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await DatabaseHelper.instance.deleteTodo(id);
      
      final currentState = state;
      if (currentState is TodoLoaded) {
        final todos = currentState.todos.where((t) => t.id != id).toList();
        emit(TodoLoaded(todos));
      }
    } catch (e) {
      emit(TodoError('Failed to delete todo: ${e.toString()}'));
    }
  }

  Future<void> toggleTodoStatus(Todo todo) async {
    try {
      final updatedTodo = todo.toggleComplete();
      await updateTodo(updatedTodo);
    } catch (e) {
      emit(TodoError('Failed to toggle todo status: ${e.toString()}'));
    }
  }

  Future<void> searchTodos(int userId, String query) async {
    emit(TodoLoading());
    
    try {
      if (query.isEmpty) {
        await fetchTodos(userId);
        return;
      }
      
      final todos = await DatabaseHelper.instance.searchTodos(userId, query);
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError('Failed to search todos: ${e.toString()}'));
    }
  }
}