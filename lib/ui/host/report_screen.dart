import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/export_utils.dart';

class ReportHostScreen extends ConsumerWidget {
  const ReportHostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    // Sort a COPY — never mutate the provider-owned list.
    final players = [...session.players]
      ..sort((a, b) => b.score.compareTo(a.score));
    final quiz = session.quiz;
    final totalQs = quiz?.questions.length ?? 0;
    final totalCorrect =
        players.fold<int>(0, (s, p) => s + p.correctCount);
    final totalAttempts = players.length * totalQs;
    final totalWrong = (totalAttempts - totalCorrect).clamp(0, 1 << 30);
    final accuracy = totalAttempts == 0
        ? 0.0
        : (totalCorrect / totalAttempts) * 100;
    final avgScore = players.isEmpty
        ? 0
        : (players.fold<int>(0, (s, p) => s + p.score) / players.length).round();
    final maxScore = players.isEmpty
        ? 0
        : players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final isBusy = ValueNotifier<bool>(false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        ref.read(gameSessionProvider.notifier).reset();
        if (context.mounted) context.go('/library');
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          tooltip: 'Back to home',
          onPressed: () {
            ref.read(gameSessionProvider.notifier).reset();
            context.go('/library');
          },
        ),
        title: Text('Game Report',
            style: AppText.heading(fontSize: 20, color: AppColors.textDark)),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isBusy,
            builder: (context, busy, _) => PopupMenuButton<String>(
              enabled: !busy && players.isNotEmpty,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.textDark))
                  : const Icon(Icons.download_rounded, color: AppColors.textDark),
              tooltip: 'Export results',
              onSelected: (value) async {
                final title = quiz?.title ?? 'Quiz';
                isBusy.value = true;
                try {
                  if (value == 'csv') {
                    await shareResultsCsv(title, players);
                  } else if (value == 'pdf') {
                    await shareResultsPdf(
                      quizTitle: title,
                      players: players,
                      quiz: quiz,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                } finally {
                  isBusy.value = false;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.picture_as_pdf_rounded,
                          color: AppColors.primaryPink),
                      title: Text('Detailed PDF report'),
                    )),
                PopupMenuItem(
                    value: 'csv',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.table_chart_rounded,
                          color: AppColors.primaryTeal),
                      title: Text('CSV / Excel'),
                    )),
              ],
            ),
          ),
        ],
      ),
      body: players.isEmpty
          ? _EmptyState(quizTitle: quiz?.title)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary stats row
                _SummaryRow(
                  totalPlayers: players.length,
                  totalQuestions: totalQs,
                  avgScore: avgScore,
                  accuracy: accuracy,
                ),
                const SizedBox(height: 20),

                // Score distribution bar chart
                _SectionCard(
                  title: 'Score Distribution',
                  child: SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: (maxScore == 0 ? 1 : maxScore * 1.1),
                        barGroups: List.generate(
                            players.length.clamp(0, 20), (i) {
                          final p = players[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: p.score.toDouble(),
                                color: i == 0
                                    ? AppColors.primaryPink
                                    : AppColors.primaryTeal,
                                width: 22,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= players.length) return const SizedBox();
                                final name = players[i].name;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    name.length > 6
                                        ? '${name.substring(0, 6)}…'
                                        : name,
                                    style: AppText.body(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString(),
                                    style: AppText.body(fontSize: 10));
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => const FlLine(
                            color: AppColors.divider,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Accuracy pie chart — only meaningful when there are attempts.
                if (totalAttempts > 0)
                  _SectionCard(
                    title: 'Accuracy Overview',
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: totalCorrect.toDouble(),
                              title:
                                  'Correct\n${((totalCorrect / totalAttempts) * 100).toStringAsFixed(0)}%',
                              color: AppColors.primaryTeal,
                              radius: 60,
                              titleStyle: AppText.heading(
                                  fontSize: 12, color: Colors.white),
                            ),
                            if (totalWrong > 0)
                              PieChartSectionData(
                                value: totalWrong.toDouble(),
                                title:
                                    'Wrong\n${((totalWrong / totalAttempts) * 100).toStringAsFixed(0)}%',
                                color: AppColors.primaryPink,
                                radius: 60,
                                titleStyle: AppText.heading(
                                    fontSize: 12, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Per-player leaderboard
                _SectionCard(
                  title: 'Final Standings',
                  child: Column(
                    children: players.asMap().entries.map((e) {
                      final rank = e.key + 1;
                      final p = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _RankBadge(rank: rank),
                          title: Text(p.name,
                              style: AppText.heading(fontSize: 16)),
                          subtitle: Text(
                              'Correct: ${p.correctCount}${totalQs > 0 ? '/$totalQs' : ''} • Best streak: ${p.bestStreak}',
                              style: AppText.body(
                                  fontSize: 12, color: AppColors.textMuted)),
                          trailing: Text(
                            '${p.score} pts',
                            style: AppText.heading(
                              fontSize: 16,
                              color: rank == 1
                                  ? const Color(0xFFD4A017)
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalPlayers;
  final int totalQuestions;
  final int avgScore;
  final double accuracy;
  const _SummaryRow({
    required this.totalPlayers,
    required this.totalQuestions,
    required this.avgScore,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatPill(label: 'Players', value: '$totalPlayers'),
      const SizedBox(width: 8),
      _StatPill(label: 'Questions', value: '$totalQuestions'),
      const SizedBox(width: 8),
      _StatPill(label: 'Avg Score', value: '$avgScore'),
      const SizedBox(width: 8),
      _StatPill(label: 'Accuracy', value: '${accuracy.toStringAsFixed(0)}%'),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hardShadow, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: AppColors.hardShadow,
                offset: Offset(2, 2),
                blurRadius: 0),
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: AppText.body(
                    fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value,
                style: AppText.heading(
                    fontSize: 18, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? quizTitle;
  const _EmptyState({this.quizTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No results yet',
                style: AppText.heading(fontSize: 22, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              quizTitle == null
                  ? 'No players completed the session.'
                  : 'No players completed "$quizTitle".',
              textAlign: TextAlign.center,
              style:
                  AppText.body(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hardShadow, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.hardShadow,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.heading(fontSize: 18)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isPodium = rank <= 3;
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '#$rank';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPodium
            ? [
                const Color(0xFFFFF9C4),
                const Color(0xFFF5F5F5),
                const Color(0xFFEFEBE9)
              ][rank - 1]
            : const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: isPodium
            ? Border.all(
                color: [
                  const Color(0xFFFFD700),
                  const Color(0xFFBDBDBD),
                  const Color(0xFF8D6E63)
                ][rank - 1],
                width: 2)
            : null,
      ),
      child: Center(
        child: Text(medal,
            style: isPodium
                ? const TextStyle(fontSize: 20)
                : AppText.heading(fontSize: 14, color: AppColors.textMuted)),
      ),
    );
  }
}

