import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_sqlite/blocs/auth_cubit.dart';
import 'package:todo_sqlite/blocs/todo_cubit.dart';
import 'package:todo_sqlite/models/todo_model.dart';
import 'package:todo_sqlite/pages/add_edit_todo_page.dart';
import 'package:todo_sqlite/widgets/todo_item.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  String _currentFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() {
    final user = (context.read<AuthCubit>().state as AuthAuthenticated).user;
    context.read<TodoCubit>().fetchTodos(user.id!, filter: _currentFilter);
  }

  void _onFilterChanged(String? filter) {
    if (filter != null) {
      setState(() {
        _currentFilter = filter;
      });
      _loadTodos();
    }
  }

  void _onSearch(String query) {
    final user = (context.read<AuthCubit>().state as AuthAuthenticated).user;
    context.read<TodoCubit>().searchTodos(user.id!, query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('My Todos'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _loadTodos();
              },
            ),
          PopupMenuButton<String>(
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Todos'),
              ),
              const PopupMenuItem(
                value: 'active',
                child: Text('Active'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
      body: BlocConsumer<TodoCubit, TodoState>(
        listener: (context, state) {
          if (state is TodoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TodoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TodoLoaded) {
            final todos = state.todos;
            
            if (todos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.checklist,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentFilter == 'completed'
                          ? 'No completed todos'
                          : _currentFilter == 'active'
                              ? 'No active todos'
                              : 'No todos yet',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add a new todo',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadTodos();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoItem(
                    todo: todo,
                    onToggle: () {
                      context.read<TodoCubit>().toggleTodoStatus(todo);
                    },
                    onDelete: () {
                      _showDeleteDialog(todo);
                    },
                    onTap: () {
                      _navigateToEditTodo(todo);
                    },
                  );
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTodo,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddTodo() {
    final user = (context.read<AuthCubit>().state as AuthAuthenticated).user;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoPage(
          userId: user.id!,
          onSave: () {
            _loadTodos();
          },
        ),
      ),
    );
  }

  void _navigateToEditTodo(Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoPage(
          userId: todo.userId,
          todo: todo,
          onSave: () {
            _loadTodos();
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoCubit>().deleteTodo(todo.id!);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Todo deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      context.read<TodoCubit>().addTodo(todo);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}