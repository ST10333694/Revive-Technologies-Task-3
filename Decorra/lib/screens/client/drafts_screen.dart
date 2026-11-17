import 'package:flutter/material.dart';

import '../../models/decor_item.dart';
import '../../models/quote_draft.dart';
import '../../services/draft_repository.dart';
import '../../widgets/empty_state.dart';
import 'customize_theme_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _repo = DraftRepository();
  late final Stream<List<QuoteDraft>> _drafts = _repo.watchMine();

  Future<void> _delete(QuoteDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text('This removes the draft for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    _repo.delete(d.id).catchError((_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete. Check your connection.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Designs')),
      body: StreamBuilder<List<QuoteDraft>>(
        stream: _drafts,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load your drafts',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No saved designs',
              message: 'Use Save as Draft on the quote screen to keep a design here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = list[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(d.themeName.isEmpty ? 'Custom design' : d.themeName),
                  subtitle: Text(
                    '${d.lines.length} ${d.lines.length == 1 ? 'item' : 'items'}'
                    ' · ${moneyText(d.subtotalCents)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete draft',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(d),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomizeThemeScreen(
                        themeId: d.themeId,
                        themeName: d.themeName,
                        draft: d,
                      ),
                    ),
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