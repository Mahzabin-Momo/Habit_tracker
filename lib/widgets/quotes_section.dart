
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../providers/quote_provider.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onRefresh;
  final String userId; // 🔧 Added userId

  const QuoteCard({
    super.key,
    required this.quote,
    required this.onRefresh,
    required this.userId, // 🔧 Required this
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.deepPurple.shade700, Colors.deepPurple.shade900]
                : [Colors.purple.shade100, Colors.purple.shade200],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, size: 24, color: Colors.white70),
              const SizedBox(height: 8),
              Text(
                quote.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '- ${quote.author}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: quote.isFavorite ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      quoteProvider.toggleFavorite(quote, userId); // ✅ Pass userId
                    },
                    tooltip: quote.isFavorite ? 'Unfavorite' : 'Add to favorites',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuotesSection extends StatelessWidget {
  final String userId;

  const QuotesSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteProvider>(
      builder: (context, quoteProvider, _) {
        if (quoteProvider.isLoading && quoteProvider.quotes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Motivation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: quoteProvider.refreshQuotes,
                    tooltip: 'Refresh quotes',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: quoteProvider.quotes.length,
                itemBuilder: (context, index) {
                  return QuoteCard(
                    quote: quoteProvider.quotes[index],
                    onRefresh: quoteProvider.refreshQuotes,
                    userId: userId, // ✅ Pass it to QuoteCard
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
 

