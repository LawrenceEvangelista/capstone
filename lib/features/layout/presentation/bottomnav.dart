import 'package:flutter/material.dart';
import 'package:testapp/features/home/presentation/screens/home_screen.dart';
import 'package:testapp/features/stories/presentation/screens/stories_screen.dart';
import 'package:testapp/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:testapp/features/quiz/presentation/screens/quiz_list_screen.dart';
import 'package:testapp/features/dictionary/presentation/screens/dictionary_screen.dart';
import 'package:provider/provider.dart';
import '../../../../providers/localization_provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const StoriesScreen(),
    const FavoritesScreen(),
    const QuizListScreen(),
    const DictionaryScreen(),
  ];

  static const List<String> _labelKeys = [
    'home',
    'stories',
    'favorites',
    'quiz',
    'dictionary',
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
          final localization = Provider.of<LocalizationProvider>(context, listen: false);
          return BottomNavigationBarItem(
            icon: Icon(_getIcon(index)),
            label: localization.translate(_labelKeys[index]),
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
