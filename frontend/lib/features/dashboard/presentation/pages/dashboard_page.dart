import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const Center(
      child: Text(
        'Home Placeholder',
        style: TextStyle(fontSize: 24, fontFamily: 'Inter', color: Color(0xFF154212)),
      ),
    ),
    const Center(
      child: Text(
        'Missions Placeholder',
        style: TextStyle(fontSize: 24, fontFamily: 'Inter', color: Color(0xFF154212)),
      ),
    ),
    const Center(
      child: Text(
        'Leaderboard Placeholder',
        style: TextStyle(fontSize: 24, fontFamily: 'Inter', color: Color(0xFF154212)),
      ),
    ),
    const Center(
      child: Text(
        'Profile Placeholder',
        style: TextStyle(fontSize: 24, fontFamily: 'Inter', color: Color(0xFF154212)),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        title: const Text('EcoEcho', style: TextStyle(fontFamily: 'Be Vietnam Pro', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF154212),
        elevation: 0,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF154212),
        unselectedItemColor: const Color(0xFF72796E),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}