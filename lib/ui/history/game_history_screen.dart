import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/providers/history_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/export_utils.dart';
import 'package:quizzapp/ui/shared/app_bottom_nav.dart';

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  final _expandedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        centerTitle: true,
        title: Text('Match History', style: AppText.heading(fontSize: 20, color: AppColors.primaryTeal)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => context.go('/'),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: history.isEmpty
          ? Center(
              child: Text(
                'No matches played yet.\nHost or join a game to see your history!',
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.textMuted, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = history[index];
                final isHost = match.isHost;
                final isExpanded = _expandedIds.contains(match.id);
                final players = isHost
                    ? (match.parsedPlayerDetails.map(PlayerScore.fromJson).toList()
                      ..sort((a, b) => a.rank.compareTo(b.rank)))
                    : <PlayerScore>[];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hardShadow, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.hardShadow,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header row — always visible
                      InkWell(
                        onTap: isHost
                            ? () => setState(() {
                                  if (_expandedIds.contains(match.id)) {
                                    _expandedIds.remove(match.id);
                                  } else {
                                    _expandedIds.add(match.id);
                                  }
                                })
                            : null,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isHost
                                      ? AppColors.primaryPink.withValues(alpha: 0.2)
                                      : AppColors.primaryTeal.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    isHost ? Icons.campaign_rounded : Icons.sports_esports_rounded,
                                    color: isHost ? AppColors.primaryPink : AppColors.primaryTeal,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.title,
                                      style: AppText.heading(fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${match.playedAt.month}/${match.playedAt.day}/${match.playedAt.year} • ${match.totalPlayers} Players',
                                      style: AppText.body(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isHost)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rank #${match.rank}',
                                      style: AppText.heading(fontSize: 14, color: AppColors.primaryTeal),
                                    ),
                                    Text(
                                      '${match.score} pts',
                                      style: AppText.body(fontSize: 12, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                              if (isHost)
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textMuted,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded content — host only
                      if (isExpanded && isHost) ...[
                        const Divider(height: 1, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (players.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No player data available.',
                                    style: AppText.body(fontSize: 14, color: AppColors.textMuted),
                                  ),
                                )
                              else ...[
                                Text('Final Standings',
                                    style: AppText.heading(fontSize: 14, color: AppColors.textDark)),
                                const SizedBox(height: 10),
                                ...players.map((p) {
                                  final medal = p.rank == 1
                                      ? '🥇'
                                      : p.rank == 2
                                          ? '🥈'
                                          : p.rank == 3
                                              ? '🥉'
                                              : '#${p.rank}';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            medal,
                                            style: p.rank <= 3
                                                ? const TextStyle(fontSize: 18)
                                                : AppText.body(fontSize: 13, color: AppColors.textMuted),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: AppText.body(fontSize: 14, color: AppColors.textDark),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${p.correctCount} correct',
                                          style: AppText.body(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${p.score} pts',
                                          style: AppText.heading(fontSize: 14, color: AppColors.textDark),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final title = match.quizTitle ?? match.title;
                                    await shareResultsCsv(title, players);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.hardShadow, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.hardShadow,
                                          offset: Offset(3, 3),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.download_rounded,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Download Results (CSV)',
                                          style: AppText.heading(fontSize: 14, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

