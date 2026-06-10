import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF5),
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF154212),
            fontWeight: FontWeight.bold,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 72, color: Color(0xFF154212)),
            SizedBox(height: 16),
            Text(
              'Profile details will load here dynamically.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF72796E),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
