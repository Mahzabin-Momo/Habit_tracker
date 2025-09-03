import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/theme_provider.dart'; // <-- import ThemeProvider
import '../screens/progress_screen.dart';
import '../screens/favorite_quotes_screen.dart';
import '../screens/habit_form_screen.dart';
import '../widgets/home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _quoteTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startQuoteTimer();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _startQuoteTimer() {
    const oneDay = Duration(days: 1);
    _quoteTimer = Timer.periodic(oneDay, (_) => _refreshQuote());
  }

  Future<void> _initializeData() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId != null) {
      await Provider.of<HabitProvider>(context, listen: false).loadHabits(userId);
      await Provider.of<QuoteProvider>(context, listen: false).loadFavorites(userId);
      await _refreshQuote();
    }
  }

  Future<void> _refreshQuote() async {
    await Provider.of<QuoteProvider>(context, listen: false).refreshQuotes();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _getSelectedScreen(String userId) {
    switch (_selectedIndex) {
      case 0:
        return HomeContent(userId: userId, refreshQuote: _refreshQuote);
      case 1:
        return const ProgressScreen();
      case 2:
        return const FavoriteQuotesScreen();
      default:
        return HomeContent(userId: userId, refreshQuote: _refreshQuote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user?.uid ?? '';
    final themeProvider = Provider.of<ThemeProvider>(context); // <-- get ThemeProvider

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Habit Tracker'
              : _selectedIndex == 1
                  ? 'Progress'
                  : 'Favorite Quotes',
        ),
        actions: [
          // 🔥 Theme toggle button added here
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshQuote();
                Provider.of<HabitProvider>(context, listen: false).loadHabits(userId);
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _getSelectedScreen(userId),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Quotes'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HabitFormScreen(userId: userId),
                  ),
                );
                _initializeData();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
