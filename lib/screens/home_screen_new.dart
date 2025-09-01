import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/quote_provider.dart';
import '../screens/progress_screen.dart';
import '../screens/favorite_quotes_screen.dart';
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
    _quoteTimer = Timer.periodic(oneDay, (timer) {
      _refreshQuote();
    });
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

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user?.uid ?? '';

    final List<Widget> pages = [
      HomeContent(
        userId: userId,
        refreshQuote: _refreshQuote,
      ),
      const ProgressScreen(),
      const FavoriteQuotesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshQuote();
                Provider.of<HabitProvider>(context, listen: false)
                    .loadHabits(userId);
              },
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Quotes',
          ),
        ],
      ),
    );
  }
}
