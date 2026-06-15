import 'package:frontend/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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
  bool _obscurePassword = true;

  // Location data
  List<dynamic> _allRegions = [];
  List<dynamic> _allProvinces = [];
  List<dynamic> _allCities = [];

  List<dynamic> _filteredProvinces = [];
  List<dynamic> _filteredCities = [];

  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    final regionStr = await rootBundle.loadString('assets/json/region.json');
    final provinceStr = await rootBundle.loadString('assets/json/province.json');
    final cityStr = await rootBundle.loadString('assets/json/city-municipality.json');
    setState(() {
      _allRegions = json.decode(regionStr)['RECORDS'];
      _allProvinces = json.decode(provinceStr)['RECORDS'];
      _allCities = json.decode(cityStr)['RECORDS'];
      _filteredProvinces = [];
      _filteredCities = [];
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields to join the movement.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address containing "@".'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (password.length <= 8 || !password.contains(RegExp(r'[a-zA-Z]')) || !password.contains(RegExp(r'[0-9]'))) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be longer than 8 characters and contain both numbers and letters.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    final accepted = await _showTermsAndConditions();
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must accept the terms and conditions to create an account.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    context.read<AuthBloc>().add(
      SignupRequested(
        username: username,
        email: email,
        password: password,
        ecoScore: 0.0,
        region: _selectedRegion?['regDesc'],
        province: _selectedProvince?['provDesc'],
        city: _selectedCity?['citymunDesc'],
      ),
    );
  }

  Future<bool> _showTermsAndConditions() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Terms & Conditions'),
            content: const SingleChildScrollView(
              child: Text(
                "Welcome to EcoEcho! By accessing or using our application, you agree to comply with and be bound by the following Terms and Conditions and community policies.\n\n1. Core Community Guidelines\nEcoEcho is a place for positive environmental action. Users are expected to log honest, authentic actions and engage with other buddies in a constructive and respectful manner. Spamming, posting fake action images, or abusing other members will result be immediate suspension.\n\n2. Account Security\nYou are responsible for maintaining the confidentiality of your login credentials. If you detect any unauthorized usage of your account, you should contact our support team immediately.\n\n3. Intellectual Property and Photo Submission\nBy uploading photos as proof of green activities, you grant EcoEcho a non-exclusive license to host and display the content. You represent that you own the rights to the uploaded media and that it does not infringe on anyone's rights.\n\n4. Modifications to Service\nEcoEcho reserves the right to modify, suspend, or discontinue any part of the service, including gamified scoring metrics or user tiers, at any time without prior warning.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Agree'),
              ),
            ],
          ),
        ) ??
        false;
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
                content: Text('Welcome ${state.user.username}! Secure cloud registration completed.'),
                backgroundColor: colorScheme.secondary,
              ),
            );
            
            // Navigate directly to the live dashboard on successful registration
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/eelogo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.eco,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
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
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E).withOpacity(0.7) : Colors.white.withOpacity(0.7), // Fixed cross-platform compatible transparency format
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.04),
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
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
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
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
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
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                hintText: '••••••••',
                                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
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
                            // Region Dropdown
                            DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<Map<String, dynamic>>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.map, color: colorScheme.onSurfaceVariant),
                                    hintText: 'Select Region',
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                  ),
                                  items: _allRegions.map((region) {
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: region,
                                      child: Text(region['regDesc'] ?? ''),
                                    );
                                  }).toList(),
                                  value: _selectedRegion,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRegion = value;
                                      _selectedProvince = null;
                                      _selectedCity = null;
                                      // Filter provinces for selected region
                                      _filteredProvinces = _allProvinces.where((p) => p['regCode'] == value?['regCode']).toList();
                                      _filteredCities = [];
                                    });
                                  },
                                ),
                            ),
                            const SizedBox(height: 12),
                            // Province Dropdown
                            DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<Map<String, dynamic>>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.location_city, color: colorScheme.onSurfaceVariant),
                                    hintText: 'Select Province',
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                  ),
                                  items: _filteredProvinces.map((prov) {
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: prov,
                                      child: Text(prov['provDesc'] ?? ''),
                                    );
                                  }).toList(),
                                  value: _selectedProvince,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProvince = value;
                                      _selectedCity = null;
                                      // Filter cities for selected province
                                      _filteredCities = _allCities.where((c) => c['provCode'] == value?['provCode']).toList();
                                    });
                                  },
                                ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonHideUnderline(
          child: DropdownButtonFormField<Map<String, dynamic>>(
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city, color: colorScheme.onSurfaceVariant),
              hintText: 'Select City/Municipality',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B2F2A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
            ),
            items: _filteredCities.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Text(city['citymunDesc'] ?? ''),
              );
            }).toList(),
            value: _selectedCity,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
          ),
        ),
                            const SizedBox(height: 20),

                            
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