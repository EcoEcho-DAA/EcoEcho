import 'package:equatable/equatable.dart';

abstract class MissionsState extends Equatable {
  const MissionsState();
  
  @override
  List<Object?> get props => [];
}

class MissionsInitial extends MissionsState {}

class MissionsLoading extends MissionsState {}

class MissionsLoaded extends MissionsState {
  final List<dynamic> missions;
  final Map<String, dynamic> analytics;

  const MissionsLoaded({required this.missions, required this.analytics});

  @override
  List<Object?> get props => [missions, analytics];
}

class MissionsError extends MissionsState {
  final String errorMessage;

  const MissionsError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
