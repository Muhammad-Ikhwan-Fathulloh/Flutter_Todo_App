import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthCubit extends Cubit<User?> {
  AuthCubit() : super(null);

  final String baseUrl =
      "https://694033c6993d68afba6b507c.mockapi.io/users";

  /// LOGIN EMAIL + PASSWORD
  Future<void> login(String email, String password) async {
    final response = await http.get(Uri.parse(baseUrl));
    final List users = jsonDecode(response.body);

    final user = users.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => null,
    );

    if (user == null) {
      throw Exception("Email atau password salah");
    }

    emit(User.fromJson(user));
  }

  /// REGISTER
  Future<void> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    emit(User.fromJson(jsonDecode(response.body)));
  }

  void logout() => emit(null);
}