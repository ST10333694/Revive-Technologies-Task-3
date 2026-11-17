import 'package:flutter/material.dart';

import '../../theme.dart';
import 'create_event_screen.dart';
import 'portfolio_screen.dart';

class EventCreatedScreen extends StatelessWidget {
  const EventCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: sand),
              const SizedBox(height: 16),
              Text('Event Created!', style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Your event has been added to your portfolio.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                ),
                child: const Text('View in Portfolio'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                ),
                child: const Text('Create Another Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}