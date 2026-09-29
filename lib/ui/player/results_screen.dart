import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameSessionProvider.notifier).endSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final players = [...session.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final wasHost = ref.read(gameSessionProvider).isHost;
        ref.read(gameSessionProvider.notifier).reset();
        if (context.mounted) context.go(wasHost ? '/library' : '/');
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            Text(
              'Final Results',
              style: AppText.heading(
                color: AppColors.textDark,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Here's how everyone did!",
              style: AppText.body(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Podium
            if (players.isNotEmpty) _PodiumSection(players: players),

            const SizedBox(height: 16),

            // Full leaderboard list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: players.length,
                itemBuilder: (ctx, i) {
                  final p = players[i];
                  final isFirst = i == 0;
                  final medal = i == 0
                      ? '🥇'
                      : i == 1
                          ? '🥈'
                          : i == 2
                              ? '🥉'
                              : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? const Color(0xFFFFF9C4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.hardShadow,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.hardShadow,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: medal != null
                              ? Text(medal,
                                  style: const TextStyle(fontSize: 24))
                              : Text('#${i + 1}',
                                  style: AppText.heading(
                                      color: AppColors.textMuted,
                                      fontSize: 16)),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              SvgAssets.avatars[
                                  p.avatarId % SvgAssets.avatars.length],
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: AppText.heading(
                                      fontSize: 16,
                                      color: AppColors.textDark)),
                              Text('${p.correctCount} correct',
                                  style: AppText.body(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${p.score}',
                            style: AppText.heading(
                                fontSize: 20,
                                color: AppColors.textDark)),
                        const SizedBox(width: 4),
                        Text('pts',
                            style: AppText.body(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(gameSessionProvider.notifier).reset();
                        context.go('/');
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.hardShadow, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.hardShadow,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text('Play Again',
                              style: AppText.heading(
                                color: AppColors.textDark,
                                fontSize: 18,
                              )),
                        ),
                      ),
                    ),
                  ),
                  if (session.isHost) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/report'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.hardShadow, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.hardShadow,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('View Report',
                                style: AppText.heading(
                                  color: Colors.white,
                                  fontSize: 18,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<dynamic> players;
  const _PodiumSection({required this.players});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (players.length > 1)
            _PodiumBar(player: players[1], rank: 2, barHeight: 78),
          const SizedBox(width: 6),
          _PodiumBar(player: players[0], rank: 1, barHeight: 108),
          const SizedBox(width: 6),
          if (players.length > 2)
            _PodiumBar(player: players[2], rank: 3, barHeight: 58),
        ],
      ),
    );
  }
}

class _PodiumBar extends StatelessWidget {
  final dynamic player;
  final int rank;
  final double barHeight;

  const _PodiumBar({
    required this.player,
    required this.rank,
    required this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = colors[rank - 1];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Center(
          child: SvgPicture.string(
            SvgAssets.avatars[player.avatarId % SvgAssets.avatars.length],
            width: 32,
            height: 32,
          ),
        ),
        SvgPicture.string(
          rank == 1 ? SvgAssets.medalGold : rank == 2 ? SvgAssets.medalSilver : SvgAssets.medalBronze,
          width: 20,
          height: 20,
        ),
        const SizedBox(height: 4),
        Container(
          width: rank == 1 ? 76.0 : 62.0,
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            border: Border.all(color: color, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (player.name as String).split(' ').first,
                style: AppText.body(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${player.score}',
                style: AppText.heading(
                  fontSize: rank == 1 ? 18 : 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
