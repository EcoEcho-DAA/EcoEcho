import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignupRequested>(_onSignupRequested);
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await ApiService.post('/api/auth/signup', {
        'username': event.username,
        'email': event.email,
        'password': event.password,
        'ecoScore': event.ecoScore,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final user = UserModel.fromJson(responseData['user']);
        final percentileRank = responseData['percentileRank'] as int?;
        
        emit(AuthSuccess(user: user, percentileRank: percentileRank));
      } else {
        emit(AuthFailure(responseData['error'] ?? 'Signup failed'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final response = await ApiService.post('/api/auth/login', {
        'email': event.email,
        'password': event.password,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(responseData['user']);
        
        emit(AuthSuccess(user: user));
      } else {
        emit(AuthFailure(responseData['error'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}