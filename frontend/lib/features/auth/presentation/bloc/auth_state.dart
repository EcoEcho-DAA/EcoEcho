import 'auth_bloc.dart'; // Imports the User class definition defined above

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final int percentileRank;

  AuthSuccess({required this.user, this.percentileRank = 0});
}

class AuthFailure extends AuthState {
  final String errorMessage;

  AuthFailure({required this.errorMessage});
}