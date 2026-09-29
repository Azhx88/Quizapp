import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MidLeaderboardScreen extends ConsumerWidget {
  const MidLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final players = [...session.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final wasHost = ref.read(gameSessionProvider).isHost;
        ref.read(gameSessionProvider.notifier).reset();
        context.go(wasHost ? '/library' : '/');
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Leaderboard',
              style: AppText.heading(
                color: AppColors.textDark,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'After this round',
              style: AppText.body(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 20),

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
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? const Color(0xFFFFF9C4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                          width: 36,
                          child: medal != null
                              ? Text(medal,
                                  style: const TextStyle(fontSize: 24),
                                  textAlign: TextAlign.center)
                              : Text('#${i + 1}',
                                  style: AppText.heading(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              SvgAssets.avatars[p.avatarId % SvgAssets.avatars.length],
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: AppText.heading(
                              fontSize: 16,
                              color: isFirst
                                  ? const Color(0xFF7D6000)
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          '${p.score}',
                          style: AppText.heading(
                            fontSize: 20,
                            color: isFirst
                                ? const Color(0xFFD4A017)
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('pts',
                            style: AppText.body(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: session.isHost
                  ? GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: double.infinity,
                        height: 60,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Next Question',
                                style: AppText.heading(
                                  color: Colors.white,
                                  fontSize: 20,
                                )),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      '⏳  Waiting for host…',
                      style: AppText.body(color: AppColors.textMuted, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
