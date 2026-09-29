import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/network_provider.dart';

class PowerUpOverlay extends ConsumerWidget {
  const PowerUpOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    if (!session.settings.powerUpsEnabled) return const SizedBox();

    final lp = session.localPlayer;
    if (lp == null) return const SizedBox();

    final powerUps = <_PowerUp>[
      if (session.settings.powerUp50_50 && !lp.usedPowerUp50)
        const _PowerUp('50/50', '⚡', '50_50'),
      if (session.settings.powerUpDoublePoints && !lp.usedPowerUpDouble)
        const _PowerUp('2×', '🎯', 'double_points'),
      if (session.settings.powerUpTimeFreeze && !lp.usedPowerUpFreeze)
        const _PowerUp('Freeze', '🧊', 'time_freeze'),
    ];

    if (powerUps.isEmpty) return const SizedBox();

    return Positioned(
      bottom: 8,
      right: 8,
      child: Row(
        children: powerUps.map((pu) => _PowerUpButton(
          powerUp: pu,
          onTap: () {
            ref.read(networkServiceProvider).sendToHost(
              PowerUpMessage(powerUpType: pu.type),
            );
          },
        )).toList(),
      ),
    );
  }
}

class _PowerUp {
  final String label, emoji, type;
  const _PowerUp(this.label, this.emoji, this.type);
}

class _PowerUpButton extends StatelessWidget {
  final _PowerUp powerUp;
  final VoidCallback onTap;
  const _PowerUpButton({required this.powerUp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FloatingActionButton.small(
        heroTag: powerUp.type,
        onPressed: onTap,
        tooltip: powerUp.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(powerUp.emoji, style: const TextStyle(fontSize: 16)),
            Text(powerUp.label,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
