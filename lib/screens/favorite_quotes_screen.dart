import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/quote_provider.dart';

class FavoriteQuotesScreen extends StatelessWidget {
  const FavoriteQuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, child) {
          final favoriteQuotes = quoteProvider.favoriteQuotes;
          
          if (favoriteQuotes.isEmpty) {
            return const Center(
              child: Text('No favorite quotes yet'),
            );
          }

          return ListView.builder(
            itemCount: favoriteQuotes.length,
            itemBuilder: (context, index) {
              final quote = favoriteQuotes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(quote.text),
                  subtitle: Text(quote.author),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (userId != null) {
                        quoteProvider.toggleFavorite(quote, userId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
