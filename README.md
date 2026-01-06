# Todo App Firebase

## 📦 **Dependensi yang Diperlukan (pubspec.yaml)**

```yaml
name: todo_app
description: A Todo App with Firebase
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core - https://pub.dev/packages/firebase_core
  firebase_core: ^2.24.2
  
  # Firebase Auth - https://pub.dev/packages/firebase_auth
  firebase_auth: ^4.13.1
  
  # Cloud Firestore - https://pub.dev/packages/cloud_firestore
  cloud_firestore: ^4.15.1
  
  # Flutter Bloc - https://pub.dev/packages/flutter_bloc
  flutter_bloc: ^8.1.3
  
  # Equatable - https://pub.dev/packages/equatable
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
```

## 🔧 **1. main.dart**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/todo_cubit.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/todo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => TodoCubit()),
      ],
      child: MaterialApp(
        title: 'Todo App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const TodoPage();
            }
            return const LoginPage();
          },
        ),
        routes: {
          '/register': (context) => const RegisterPage(),
        },
      ),
    );
  }
}
```

## 👤 **2. models/user_model.dart**

```dart
class UserModel {
  final String uid;
  final String email;
  final String? name;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
    );
  }
}
```

## 📝 **3. models/todo_model.dart**

```dart
class TodoModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      userId: map['userId'] ?? '',
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
```

## 🔐 **4. blocs/auth_cubit.dart**

```dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import '../models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthCubit() : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        UserModel user = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userDoc.data()?['name'],
        );
        emit(AuthAuthenticated(user: user));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Terjadi kesalahan'));
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      emit(AuthLoading());
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (userCredential.user != null) {
        UserModel user = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: name.trim(),
        );
        
        await _firestore.collection('users').doc(user.uid).set(user.toMap());
        emit(AuthAuthenticated(user: user));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Terjadi kesalahan'));
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout gagal'));
    }
  }

  void checkAuthStatus() {
    User? user = _auth.currentUser;
    if (user != null) {
      UserModel userModel = UserModel(
        uid: user.uid,
        email: user.email!,
      );
      emit(AuthAuthenticated(user: userModel));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Pengguna tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Email tidak valid';
      default:
        return 'Terjadi kesalahan';
    }
  }
}

part 'auth_state.dart';
```

## 📋 **5. blocs/auth_state.dart**

```dart
part of 'auth_cubit.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
```

## ✅ **6. blocs/todo_cubit.dart**

```dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import '../models/todo_model.dart';

part 'todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TodoCubit() : super(TodoInitial());

  Stream<List<TodoModel>> streamTodos() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TodoModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  Future<void> addTodo(String title, String description) async {
    try {
      emit(TodoLoading());
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(TodoError(message: 'Pengguna tidak terautentikasi'));
        return;
      }

      final now = DateTime.now();
      final todoRef = _firestore.collection('todos').doc();
      
      TodoModel todo = TodoModel(
        id: todoRef.id,
        title: title.trim(),
        description: description.trim(),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        userId: userId,
      );

      await todoRef.set(todo.toMap());
      emit(TodoSuccess(message: 'Todo berhasil ditambahkan'));
    } catch (e) {
      emit(TodoError(message: 'Gagal menambahkan todo'));
    }
  }

  Future<void> updateTodo(TodoModel todo) async {
    try {
      emit(TodoLoading());
      await _firestore.collection('todos').doc(todo.id).update({
        'title': todo.title.trim(),
        'description': todo.description.trim(),
        'isCompleted': todo.isCompleted,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      emit(TodoSuccess(message: 'Todo berhasil diperbarui'));
    } catch (e) {
      emit(TodoError(message: 'Gagal memperbarui todo'));
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      emit(TodoLoading());
      await _firestore.collection('todos').doc(id).delete();
      emit(TodoSuccess(message: 'Todo berhasil dihapus'));
    } catch (e) {
      emit(TodoError(message: 'Gagal menghapus todo'));
    }
  }

  Future<void> toggleTodoCompletion(TodoModel todo) async {
    try {
      await _firestore.collection('todos').doc(todo.id).update({
        'isCompleted': !todo.isCompleted,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      emit(TodoError(message: 'Gagal mengubah status todo'));
    }
  }
}

part 'todo_cubit.dart';
```

## 📄 **7. blocs/todo_state.dart**

```dart
part of 'todo_cubit.dart';

@immutable
abstract class TodoState {}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoSuccess extends TodoState {
  final String message;
  TodoSuccess({required this.message});
}

class TodoError extends TodoState {
  final String message;
  TodoError({required this.message});
}
```

## 🔑 **8. pages/login_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixText: ' ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan email';
                          }
                          if (!value.contains('@')) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixText: ' ',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Text(_isPasswordVisible ? 'Sembunyikan' : 'Tampilkan'),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan password';
                          }
                          if (value.length < 6) {
                            return 'Minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return const CircularProgressIndicator();
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                }
                              },
                              child: const Text('Login'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('Daftar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

## 📝 **9. pages/register_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixText: ' ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan nama lengkap';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixText: ' ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan email';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixText: ' ',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Text(_isPasswordVisible ? 'Sembunyikan' : 'Tampilkan'),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan password';
                        }
                        if (value.length < 6) {
                          return 'Minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        border: const OutlineInputBorder(),
                        prefixText: ' ',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                          icon: Text(_isConfirmPasswordVisible ? 'Sembunyikan' : 'Tampilkan'),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password';
                        }
                        if (value != _passwordController.text) {
                          return 'Password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const CircularProgressIndicator();
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().register(
                                      _emailController.text,
                                      _passwordController.text,
                                      _nameController.text,
                                    );
                              }
                            },
                            child: const Text('Daftar'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
```

## 📋 **10. pages/todo_page.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/todo_cubit.dart';
import '../models/todo_model.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TodoModel? _editingTodo;

  void _showTodoDialog({TodoModel? todo}) {
    _editingTodo = todo;
    if (todo != null) {
      _titleController.text = todo.title;
      _descriptionController.text = todo.description;
    } else {
      _titleController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(todo == null ? 'Tambah Todo' : 'Edit Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _titleController.clear();
                _descriptionController.clear();
                _editingTodo = null;
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();
                
                if (title.isNotEmpty) {
                  if (_editingTodo == null) {
                    context.read<TodoCubit>().addTodo(title, description);
                  } else {
                    context.read<TodoCubit>().updateTodo(
                      _editingTodo!.copyWith(
                        title: title,
                        description: description,
                      ),
                    );
                  }
                  Navigator.pop(context);
                  _titleController.clear();
                  _descriptionController.clear();
                  _editingTodo = null;
                }
              },
              child: Text(todo == null ? 'Simpan' : 'Perbarui'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String todoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Todo'),
          content: const Text('Apakah Anda yakin ingin menghapus todo ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TodoCubit>().deleteTodo(todoId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TodoCubit, TodoState>(
      listener: (context, state) {
        if (state is TodoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state is TodoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.read<TodoCubit>().state is TodoSuccess) {
              context.read<TodoCubit>().emit(TodoInitial());
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daftar Todo'),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<AuthCubit>().logout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
          body: StreamBuilder<List<TodoModel>>(
            stream: context.read<TodoCubit>().streamTodos(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final todos = snapshot.data ?? [];

              if (todos.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada todo\nTambahkan todo baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: todos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: todo.description.isNotEmpty
                          ? Text(
                              todo.description,
                              style: TextStyle(
                                color: todo.isCompleted
                                    ? Colors.grey
                                    : Colors.black54,
                              ),
                            )
                          : null,
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (value) {
                          context.read<TodoCubit>().toggleTodoCompletion(todo);
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _showTodoDialog(todo: todo),
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _confirmDelete(todo.id),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showTodoDialog(),
            child: const Text('+'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
```

## 🔐 **Firebase Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /todos/{todoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## 📱 **Instalasi & Konfigurasi**

### Langkah 1: Instal Dependensi
```bash
# Tambahkan package Firebase
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore

# Tambahkan package state management
flutter pub add flutter_bloc
flutter pub add equatable
```

### Langkah 2: Konfigurasi Firebase
1. Buat proyek di [Firebase Console](https://console.firebase.google.com/)
2. Tambahkan aplikasi Flutter
3. Jalankan perintah:
```bash
flutterfire configure
```

### Langkah 3: Struktur Database Firestore
- Collection `users`: Menyimpan data pengguna
- Collection `todos`: Menyimpan todo dengan field `userId` untuk relasi
