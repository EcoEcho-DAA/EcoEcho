import 'package:equatable/equatable.dart';

abstract class MissionsEvent extends Equatable {
  const MissionsEvent();

  @override
  List<Object?> get props => [];
}

class FetchDailyMissions extends MissionsEvent {}
