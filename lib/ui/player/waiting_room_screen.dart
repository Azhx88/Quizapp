import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/network_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    ref.listenManual(networkMessagesProvider, (_, next) {
      next.whenData((msg) {
        if (msg is GameStartingMessage) {
          if (mounted) context.pushReplacement('/question');
        } else if (msg is QuestionMessage) {
          final q = Question.fromMap(msg.data);
          ref.read(gameSessionProvider.notifier).receiveQuestion(q, timeLimit: msg.timeLimit);
          if (mounted) context.pushReplacement('/question');
        } else if (msg is PlayerListMessage) {
          final players = msg.players.map(PlayerScore.fromJson).toList();
          for (final p in players) {
            ref.read(gameSessionProvider.notifier).addPlayer(p);
          }
        } else if (msg is PlayerKickedMessage) {
          // Host kicked us — drop the session and head home immediately.
          ref.read(gameSessionProvider.notifier).reset();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You were removed by the host.')),
            );
            context.go('/');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final players = session.players;
    final localPlayer = session.localPlayer;

    return Scaffold(
      backgroundColor: AppColors.questionBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Quiz',
                    style: AppText.heading(fontSize: 48, color: const Color(0xFF1C1C1C)),
                  ),
                  TextSpan(
                    text: 'app',
                    style: AppText.heading(fontSize: 48, color: const Color(0xFFCC3333)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Local player hero card
            if (localPlayer != null) ...[
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hardShadow, width: 3),
                ),
                child: Center(
                  child: SvgPicture.string(
                    SvgAssets.avatars[localPlayer.avatarId % SvgAssets.avatars.length],
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localPlayer.name,
                style: AppText.heading(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Opacity(
                  opacity: 0.4 + 0.6 * _pulseCtrl.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for host to start…',
                        style: AppText.body(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 48),

            if (players.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Players (${players.length})',
                      style: AppText.heading(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Players grid
            Expanded(
              child: players.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⏳', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Waiting for the game to start',
                              style: TextStyle(color: Color(0xFF7F8C8D))),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: players.length,
                      itemBuilder: (ctx, i) {
                        final p = players[i];
                        final isLocal = p.name == localPlayer?.name;
                        return Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.hardShadow, width: 2),
                              ),
                              child: Center(
                                child: SvgPicture.string(
                                  SvgAssets.avatars[p.avatarId % SvgAssets.avatars.length],
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppText.body(
                                fontSize: 14,
                                color: isLocal ? AppColors.primaryTeal : Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // Bottom branding
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Quizapp',
                style: AppText.heading(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
