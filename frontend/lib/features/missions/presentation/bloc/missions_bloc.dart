import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_service.dart';
import 'missions_event.dart';
import 'missions_state.dart';

class MissionsBloc extends Bloc<MissionsEvent, MissionsState> {
  MissionsBloc() : super(MissionsInitial()) {
    on<FetchAllMissions>((event, emit) async {
      emit(MissionsLoading());
      try {
        final dailyRes = await ApiService.get('/api/missions/daily');
        final fixedRes = await ApiService.get('/api/missions/fixed');

        if (dailyRes.statusCode == 200 && fixedRes.statusCode == 200) {
          final Map<String, dynamic> dailyData = jsonDecode(dailyRes.body);
          final Map<String, dynamic> fixedData = jsonDecode(fixedRes.body);

          emit(MissionsLoaded(
            dailyMissions: dailyData['missions'] ?? [],
            analytics: dailyData['analytics'] ?? {},
            fixedMissions: fixedData['missions'] ?? [],
            prerequisites: fixedData['prerequisites'] ?? [],
          ));
        } else {
          emit(const MissionsError(errorMessage: 'Failed to load missions.'));
        }
      } catch (e) {
        emit(MissionsError(errorMessage: 'Network error: ${e.toString()}'));
      }
    });
  }
}
