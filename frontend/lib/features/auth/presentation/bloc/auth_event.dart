import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];


}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignupRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final double ecoScore;
  final String? region;
  final String? province;
  final String? city;

  const SignupRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.ecoScore,
    this.region,
    this.province,
    this.city,
  });

  @override
  List<Object?> get props => [username, email, password, ecoScore, region, province, city];
}