import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/utils/constants.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LeaderboardWidget extends StatefulWidget {
  final List<PlayerScore> players;
  const LeaderboardWidget({super.key, required this.players});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Column(
      children: sorted.asMap().entries.map((e) {
        final rank = e.key + 1;
        final p = e.value;
        return _RankRow(rank: rank, player: p, delay: e.key);
      }).toList(),
    );
  }
}

class _RankRow extends StatefulWidget {
  final int rank;
  final PlayerScore player;
  final int delay;
  const _RankRow({required this.rank, required this.player, required this.delay});

  @override
  State<_RankRow> createState() => _RankRowState();
}

class _RankRowState extends State<_RankRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    Future.delayed(Duration(milliseconds: 80 + widget.delay * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = widget.rank <= 3;
    final cs = Theme.of(context).colorScheme;
    final delta = widget.player.delta;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isTop3
                ? cs.primaryContainer.withValues(alpha: 0.6)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isTop3
                ? Border.all(color: cs.primary.withValues(alpha: 0.5))
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary.withValues(alpha: 0.15),
              child: Text(
                '#${widget.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
            title: Row(children: [
              SvgPicture.string(
                SvgAssets.avatars[widget.player.avatarId % SvgAssets.avatars.length],
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(widget.player.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            subtitle: widget.player.streak >= kStreakThreshold
                ? Text('🔥 ${widget.player.streak} streak',
                    style: const TextStyle(color: Colors.orange))
                : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.player.score} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (delta != 0)
                  Text(
                    delta > 0 ? '+$delta ▲' : '$delta ▼',
                    style: TextStyle(
                      fontSize: 11,
                      color: delta > 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
