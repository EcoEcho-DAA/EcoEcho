import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:frontend/features/ecowrap/presentation/ecowrap_story_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: MaterialApp(
        title: 'EcoEcho',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const EcoWrapStoryScreen(),
      ),
    );
  }
}