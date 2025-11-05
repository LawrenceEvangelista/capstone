import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../stories/stories_screen.dart';
import '../favorites/favorites_screen.dart';
import '../quiz/quiz_list_screen.dart';
import '../dictionary/dictionary_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  static const List<Widget> _screens = [
    HomeScreen(),
    StoriesScreen(),
    FavoritesScreen(),
    QuizListScreen(),
    DictionaryScreen(),
  ];

  static const List<String> _labels = [
    'Home',
    'Stories',
    'Favorites',
    'Quiz',
    'Dictionary',
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFFFD93D),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: List.generate(_screens.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_getIcon(index)),
            label: _labels[index],
          );
        }),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.book;
      case 2:
        return Icons.favorite;
      case 3:
        return Icons.quiz;
      case 4:
        return Icons.menu_book;  // Changed from Icons.settings to Icons.menu_book
      default:
        return Icons.home; // Default icon
    }
  }
}