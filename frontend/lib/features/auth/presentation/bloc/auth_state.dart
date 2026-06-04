import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart'; 

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;
  final int? percentileRank; 

  const AuthSuccess({required this.user, this.percentileRank});

  @override
  List<Object?> get props => [user, percentileRank];
}

class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}