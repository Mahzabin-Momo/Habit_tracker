import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote.dart';

class QuoteProvider extends ChangeNotifier {
  List<Quote> _quotes = [];
  Set<Quote> _favoriteQuotes = {};
  bool _isLoading = false;
  String? _error;
  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Quote> get quotes => _quotes;
  List<Quote> get favoriteQuotes => _favoriteQuotes.toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load favorite quotes from Firestore for the given userId.
  Future<void> loadFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_quotes')
          .get();

      _favoriteQuotes = snapshot.docs
          .map((doc) => Quote.fromFirestore(doc))
          .toSet();

      // Mark loaded favorites as isFavorite = true
      for (var fav in _favoriteQuotes) {
        fav.isFavorite = true;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load favorite quotes';
      notifyListeners();
    }
  }

  /// Toggle favorite status of a quote for the given userId.
  Future<void> toggleFavorite(Quote quote, String userId) async {
    try {
      final docId = quote.id; // Use stable doc ID based on quote text
      final quoteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorite_quotes')
          .doc(docId);

      if (_favoriteQuotes.contains(quote)) {
        // Remove from favorites
        await quoteRef.delete();
        _favoriteQuotes.removeWhere((q) => q.id == docId);
        quote.isFavorite = false;
      } else {
        // Add to favorites
        await quoteRef.set(quote.toMap());
        quote.isFavorite = true;
        _favoriteQuotes.add(quote);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update favorite quotes';
      notifyListeners();
    }
  }

  /// Check if a quote is favorite.
  bool isFavorite(Quote quote) {
    return _favoriteQuotes.contains(quote);
  }

  // Fallback quotes in case the API is unavailable
  static const List<Map<String, String>> _fallbackQuotes = [
    {
      "text": "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      "author": "Winston Churchill"
    },
    {
      "text": "It does not matter how slowly you go as long as you do not stop.",
      "author": "Confucius"
    },
    {
      "text": "The only way to do great work is to love what you do.",
      "author": "Steve Jobs"
    },
    {
      "text": "What you get by achieving your goals is not as important as what you become by achieving your goals.",
      "author": "Zig Ziglar"
    },
    {
      "text": "Success is walking from failure to failure with no loss of enthusiasm.",
      "author": "Winston Churchill"
    },
    {
      "text": "The future depends on what you do today.",
      "author": "Mahatma Gandhi"
    },
    {
      "text": "The only limit to our realization of tomorrow will be our doubts of today.",
      "author": "Franklin D. Roosevelt"
    }
  ];

  // Using the Quotable API
  static const String _baseUrl = 'https://api.quotable.io';

  /// Fetch random quotes and mark favorites properly.
  Future<void> fetchQuotes({int count = 5}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$_baseUrl/quotes/random?limit=$count'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _quotes = data.map((json) => Quote.fromJson(json)).toList();

        // Mark quotes as favorite if in _favoriteQuotes
        for (var quote in _quotes) {
          if (_favoriteQuotes.any((fav) => fav == quote)) {
            quote.isFavorite = true;
          }
        }
      } else {
        throw HttpException('Failed to load quotes');
      }
    } catch (e) {
      // Use fallback quotes if API fails
      _quotes = _getRandomFallbackQuotes(count);
      for (var quote in _quotes) {
        if (_favoriteQuotes.any((fav) => fav == quote)) {
          quote.isFavorite = true;
        }
      }
      _error = null; // Clear error since we're using fallback quotes
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Quote> _getRandomFallbackQuotes(int count) {
    final quotes = List<Map<String, String>>.from(_fallbackQuotes);
    quotes.shuffle(_random);
    return quotes
        .take(count)
        .map((q) => Quote(text: q['text']!, author: q['author']!))
        .toList();
  }

  /// Refresh quotes by fetching new ones.
  Future<void> refreshQuotes() async {
    await fetchQuotes();
  }
}


