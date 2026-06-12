import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ecoScoreController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ecoScoreController.dispose();
    super.dispose();
  }

  void _submitSignup() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ecoScoreStr = _ecoScoreController.text.trim();
    final ecoScore = double.tryParse(ecoScoreStr) ?? 0.0;

    if (username.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(
        SignupRequested(
          username: username,
          email: email,
          password: password,
          ecoScore: ecoScore,
        ),
      );
    } else {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields to join the movement.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${state.user.username}! You placed in the ${state.percentileRank}th percentile.'),
                backgroundColor: colorScheme.secondary,
              ),
            );
            // This is where to put our home navigation if ok na
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Join the Movement',
                    style: textTheme.displayLarge?.copyWith(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to start making a real-world impact with a rooted community.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name', 
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter', 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
                                hintText: 'Jane Doe',
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Email', 
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter', 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.mail_outline, color: colorScheme.onSurfaceVariant),
                                hintText: 'jane@example.com',
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Password', 
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter', 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                                hintText: '••••••••',
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Environmental Score', 
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter', 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _ecoScoreController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.compost, color: colorScheme.onSurfaceVariant),
                                hintText: '0.0',
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0), 
                                  borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            if (state is AuthLoading)
                              Center(child: CircularProgressIndicator(color: colorScheme.primary))
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _submitSignup,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Account', 
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontFamily: 'Inter', 
                                          color: colorScheme.onPrimary, 
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ', 
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Inter', 
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Log In', 
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Inter', 
                            color: colorScheme.primary, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}