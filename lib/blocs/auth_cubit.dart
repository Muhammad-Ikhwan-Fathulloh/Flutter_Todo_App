import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_sqlite/database/database_helper.dart';
import 'package:todo_sqlite/database/preferences_helper.dart';
import 'package:todo_sqlite/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    
    try {
      final userId = PreferencesHelper.getUserId();
      final rememberMe = PreferencesHelper.getRememberMe();
      
      if (userId != null && rememberMe) {
        final user = await DatabaseHelper.instance.getUserById(userId);
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          await PreferencesHelper.clearUserSession();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication status'));
    }
  }

  Future<void> login(String email, String password, bool rememberMe) async {
    emit(AuthLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      
      if (user == null) {
        emit(AuthError('User not found'));
        return;
      }
      
      if (user.password != password) {
        emit(AuthError('Invalid password'));
        return;
      }
      
      if (rememberMe) {
        await PreferencesHelper.saveUserSession(user.id!);
        await PreferencesHelper.saveRememberMe(true);
      }
      
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> register(User user) async {
    emit(AuthLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if email already exists
      final existingUser = await DatabaseHelper.instance.getUserByEmail(user.email);
      if (existingUser != null) {
        emit(AuthError('Email already registered'));
        return;
      }
      
      // Create new user
      final userId = await DatabaseHelper.instance.createUser(user);
      final newUser = user.copyWith(id: userId);
      
      emit(AuthAuthenticated(newUser));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    await PreferencesHelper.clearUserSession();
    emit(AuthUnauthenticated());
  }
}