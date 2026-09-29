import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PodiumWidget extends StatefulWidget {
  final List<PlayerScore> players;
  const PodiumWidget({super.key, required this.players});

  @override
  State<PodiumWidget> createState() => _PodiumWidgetState();
}

class _PodiumWidgetState extends State<PodiumWidget>
    with TickerProviderStateMixin {
  late AnimationController _ctrl2; // 2nd
  late AnimationController _ctrl1; // 1st (drops from top)
  late AnimationController _ctrl3; // 3rd

  @override
  void initState() {
    super.initState();
    _ctrl2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // Stagger: 2nd → 1st → 3rd
    _ctrl2.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl1.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl3.forward();
    });
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p1 = widget.players.isNotEmpty ? widget.players[0] : null;
    final p2 = widget.players.length > 1 ? widget.players[1] : null;
    final p3 = widget.players.length > 2 ? widget.players[2] : null;

    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd — slides from left
          if (p2 != null)
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _ctrl2, curve: Curves.easeOut)),
              child: _PodiumColumn(player: p2, rank: 2, height: 130),
            ),

          const SizedBox(width: 8),

          // 1st — drops from top
          if (p1 != null)
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _ctrl1, curve: Curves.bounceOut)),
              child: _PodiumColumn(player: p1, rank: 1, height: 180),
            ),

          const SizedBox(width: 8),

          // 3rd — slides from right
          if (p3 != null)
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _ctrl3, curve: Curves.easeOut)),
              child: _PodiumColumn(player: p3, rank: 3, height: 100),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PlayerScore player;
  final int rank;
  final double height;

  const _PodiumColumn({
    required this.player,
    required this.rank,
    required this.height,
  });

  static const _podiumColors = [Colors.amber, Colors.grey, Colors.brown];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white24,
          child: SvgPicture.string(
            SvgAssets.avatars[player.avatarId % SvgAssets.avatars.length],
            width: 36,
            height: 36,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
              fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${player.score}',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        // Podium block
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: _podiumColors[rank - 1].withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: SvgPicture.string(
              rank == 1 ? SvgAssets.medalGold : rank == 2 ? SvgAssets.medalSilver : SvgAssets.medalBronze,
              width: 36,
              height: 36,
            ),
          ),
        ),
      ],
    );
  }
}
