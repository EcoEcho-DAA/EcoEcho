import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_service.dart';
import 'missions_event.dart';
import 'missions_state.dart';

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc() : super(MissionsInitial()) {
    on<FetchDailyMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        final response = await ApiService.get('/api/missions/daily');
        if (response.statusCode == 200) {
          final List<dynamic> missions = jsonDecode(response.body);
          emit(MissionsLoaded(missions: missions));
        } else {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            emit(MissionsError(
              errorMessage: errorData['error'] ?? 'Failed to load missions.',
            ));
          } catch (_) {
            emit(const MissionsError(errorMessage: 'Failed to load missions.'));
          }
        }
      } catch (e) {
        emit(MissionsError(errorMessage: 'Network error: ${e.toString()}'));
      }
    });
  }
}
