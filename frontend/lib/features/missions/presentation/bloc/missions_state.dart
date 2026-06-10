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

  const MissionsLoaded({required this.missions});

  @override
  List<Object?> get props => [missions];
}

class MissionsError extends MissionsState {
  final String errorMessage;

  const MissionsError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
