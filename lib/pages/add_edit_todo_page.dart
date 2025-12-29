import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_sqlite/blocs/todo_cubit.dart';
import 'package:todo_sqlite/models/todo_model.dart';

class AddEditTodoPage extends StatefulWidget {
  final Todo? todo;
  final int userId;
  final VoidCallback onSave;

  const AddEditTodoPage({
    super.key,
    this.todo,
    required this.userId,
    required this.onSave,
  });

  @override
  State<AddEditTodoPage> createState() => _AddEditTodoPageState();
}

class _AddEditTodoPageState extends State<AddEditTodoPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _priority = 1;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _priority = widget.todo!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Todo' : 'Edit Todo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTodo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 24.0),
              // Priority Section
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  _buildPriorityButton(1, 'Low', Colors.green),
                  const SizedBox(width: 8.0),
                  _buildPriorityButton(2, 'Medium', Colors.orange),
                  const SizedBox(width: 8.0),
                  _buildPriorityButton(3, 'High', Colors.red),
                ],
              ),
              const SizedBox(height: 32.0),
              // Save Button
              ElevatedButton(
                onPressed: _saveTodo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Save Todo',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              if (widget.todo != null) ...[
                const SizedBox(height: 16.0),
                // Delete Button for editing
                OutlinedButton(
                  onPressed: _deleteTodo,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Delete Todo',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(int priority, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: _priority == priority ? color.withOpacity(0.1) : null,
            border: Border.all(
              color: _priority == priority ? color : Colors.grey.shade300,
              width: _priority == priority ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Icon(
                Icons.flag,
                color: color,
              ),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: _priority == priority 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      final todo = widget.todo == null
          ? Todo(
              title: _titleController.text,
              description: _descriptionController.text,
              isCompleted: false,
              createdAt: DateTime.now(),
              priority: _priority,
              userId: widget.userId,
            )
          : widget.todo!.copyWith(
              title: _titleController.text,
              description: _descriptionController.text,
              priority: _priority,
            );

      if (widget.todo == null) {
        context.read<TodoCubit>().addTodo(todo);
      } else {
        context.read<TodoCubit>().updateTodo(todo);
      }

      widget.onSave();
      Navigator.pop(context);
    }
  }

  void _deleteTodo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (widget.todo?.id != null) {
                context.read<TodoCubit>().deleteTodo(widget.todo!.id!);
                widget.onSave();
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}