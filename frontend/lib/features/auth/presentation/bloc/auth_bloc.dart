import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/network/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// Simple minimal User model structure to keep your existing BLoC state happy
class User {
  final String username;
  final String email;
  User({required this.username, required this.email});
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    
    // --- HANDLE USER SIGNUP ---
    on<SignupRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Map the frontend form parameters to exactly what the backend index.js schema expects
          final Map<String, dynamic> signupPayload = {
            'username': event.email.split('@')[0], // fallback username
            'first_name': event.username, // maps Full Name
            'email': event.email,
            'password': event.password,
            // Use provided location fields if available, else fallback to empty strings
            'region': event.region ?? '',
            'province': event.province ?? '',
            'city': event.city ?? '',
          };

        final response = await ApiService.post('/api/auth/register', signupPayload);

        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          
          // Save the token for instant auto-login
          ApiService.userToken = responseData['token'];
          
          // Construct a provisional user model to trigger a successful UI redirection state
          final user = User(
            username: signupPayload['first_name'],
            email: signupPayload['email'],
          );
          
          emit(AuthSuccess(user: user, percentileRank: 85));
        } else {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          emit(AuthFailure(errorMessage: errorData['message'] ?? errorData['error'] ?? 'Registration failed.'));
        }
      } catch (e) {
        emit(AuthFailure(errorMessage: 'Network error or bad response: ${e.toString()}'));
      }
    });

    // --- HANDLE USER LOGIN ---
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final Map<String, dynamic> loginPayload = {
          'email': event.email,
          'password': event.password,
        };

        final response = await ApiService.post('/api/auth/login', loginPayload);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          
          // CRITICAL STEP: Extract and store the signed JWT string token into the global ApiService memory layer
          ApiService.userToken = responseData['token'];

          final userData = responseData['user'];
          final user = User(
            username: userData['first_name'] ?? userData['username'] ?? 'User',
            email: userData['email'],
          );

          emit(AuthSuccess(user: user, percentileRank: 90));
        } else {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          emit(AuthFailure(errorMessage: errorData['message'] ?? errorData['error'] ?? 'Invalid credentials.'));
        }
      } catch (e) {
        emit(AuthFailure(errorMessage: 'Connection dropped or invalid json: ${e.toString()}'));
      }
    });
  }
}