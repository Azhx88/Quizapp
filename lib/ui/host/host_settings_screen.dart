import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/game_settings.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/settings_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/ui/shared/app_bottom_nav.dart';

class HostSettingsScreen extends ConsumerWidget {
  /// When true (default), this screen is mid-host-flow: shows the
  /// "Continue" button that proceeds into the lobby. When false, the
  /// same screen acts as the global Settings tab — no Continue button,
  /// and a bottom nav is rendered so users can move between tabs.
  final bool showContinue;
  const HostSettingsScreen({super.key, this.showContinue = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    void goHome() {
      ref.read(gameSessionProvider.notifier).reset();
      context.go(showContinue ? '/library' : '/');
    }

    return PopScope(
      canPop: !showContinue,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !showContinue) return;
        goHome();
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: 'Back to home',
          onPressed: goHome,
        ),
        title: Text(showContinue ? 'Host Settings' : 'Settings',
            style: AppText.heading(fontSize: 20, color: AppColors.primaryTeal)),
      ),
      bottomNavigationBar: showContinue
          ? null
          : const AppBottomNav(currentIndex: 3),
      body: ListView(
        children: [
          // ── Game Mode ──────────────────────────────────────────
          _Section(
            title: 'Game Mode',
            children: [
              SegmentedButton<GameMode>(
                segments: const [
                  ButtonSegment(value: GameMode.classic, label: Text('Classic')),
                  ButtonSegment(value: GameMode.instructorPaced, label: Text('Instructor')),
                  ButtonSegment(value: GameMode.teamVsTeam, label: Text('Team vs Team')),
                ],
                selected: {s.gameMode},
                onSelectionChanged: (v) => n.setGameMode(v.first),
              ),
            ],
          ),

          // ── Primary Settings ───────────────────────────────────
          _Section(
            title: 'Primary',
            children: [
              ListTile(
                title: const Text('Time per question'),
                trailing: DropdownButton<int>(
                  value: s.timePerQuestion,
                  underline: const SizedBox(),
                  items: const [5, 10, 15, 30, 60]
                      .map((t) => DropdownMenuItem(value: t, child: Text('${t}s')))
                      .toList(),
                  onChanged: (v) => n.setTimePerQuestion(v!),
                ),
              ),
              ListTile(
                title: const Text('Number of questions'),
                trailing: DropdownButton<int?>(
                  value: s.numberOfQuestions,
                  underline: const SizedBox(),
                  items: [null, 5, 10, 15, 20]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v == null ? 'All' : '$v'),
                          ))
                      .toList(),
                  onChanged: (v) => n.setNumberOfQuestions(v),
                ),
              ),
              ListTile(
                title: const Text('Max players'),
                subtitle: Text(
                  '${s.maxPlayers} ${s.maxPlayers > 80 ? "(host phone may struggle on weak WiFi)" : ""}',
                  style: TextStyle(
                    color: s.maxPlayers > 80
                        ? AppColors.primaryPink
                        : AppColors.textMuted,
                  ),
                ),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: s.maxPlayers.toDouble(),
                    min: 2,
                    max: 300,
                    divisions: 298,
                    label: '${s.maxPlayers}',
                    onChanged: (v) => n.setMaxPlayers(v.round()),
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Allow late join'),
                value: s.allowLateJoin,
                onChanged: n.setAllowLateJoin,
              ),
              SwitchListTile(
                title: const Text('Require name entry'),
                value: s.requireNameEntry,
                onChanged: n.setRequireNameEntry,
              ),
            ],
          ),

          // ── Question Settings ──────────────────────────────────
          _Section(
            title: 'Questions',
            children: [
              SwitchListTile(
                title: const Text('Shuffle questions'),
                value: s.shuffleQuestions,
                onChanged: n.setShuffleQuestions,
              ),
              SwitchListTile(
                title: const Text('Shuffle answer options'),
                value: s.shuffleAnswerOptions,
                onChanged: n.setShuffleAnswerOptions,
              ),
              SwitchListTile(
                title: const Text('Show correct answer'),
                value: s.showCorrectAnswer,
                onChanged: n.setShowCorrectAnswer,
              ),
              SwitchListTile(
                title: const Text('Show fun facts'),
                value: s.showFunFact,
                onChanged: n.setShowFunFact,
              ),
            ],
          ),

          // ── Gamification ───────────────────────────────────────
          _Section(
            title: 'Gamification',
            children: [
              SwitchListTile(
                title: const Text('Show leaderboard'),
                value: s.showLeaderboard,
                onChanged: n.setShowLeaderboard,
              ),
              if (s.showLeaderboard)
                ListTile(
                  title: const Text('Leaderboard frequency'),
                  trailing: DropdownButton<LeaderboardFrequency>(
                    value: s.leaderboardFrequency,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: LeaderboardFrequency.everyQuestion,
                          child: Text('Every question')),
                      DropdownMenuItem(
                          value: LeaderboardFrequency.every3,
                          child: Text('Every 3')),
                      DropdownMenuItem(
                          value: LeaderboardFrequency.endOnly,
                          child: Text('End only')),
                    ],
                    onChanged: (v) => n.setLeaderboardFrequency(v!),
                  ),
                ),
              SwitchListTile(
                title: const Text('Power-ups'),
                value: s.powerUpsEnabled,
                onChanged: n.setPowerUpsEnabled,
              ),
              if (s.powerUpsEnabled) ...[
                CheckboxListTile(
                  title: const Text('50/50'),
                  value: s.powerUp50_50,
                  onChanged: (v) => n.setPowerUp50_50(v!),
                ),
                CheckboxListTile(
                  title: const Text('Double points'),
                  value: s.powerUpDoublePoints,
                  onChanged: (v) => n.setPowerUpDoublePoints(v!),
                ),
                CheckboxListTile(
                  title: const Text('Time freeze'),
                  value: s.powerUpTimeFreeze,
                  onChanged: (v) => n.setPowerUpTimeFreeze(v!),
                ),
              ],
              SwitchListTile(
                title: const Text('Streak bonus'),
                value: s.streakBonusEnabled,
                onChanged: n.setStreakBonusEnabled,
              ),
            ],
          ),

          // ── Scoring ────────────────────────────────────────────
          _Section(
            title: 'Scoring',
            children: [
              SwitchListTile(
                title: const Text('Speed-based scoring'),
                subtitle: const Text('Max 1000 pts, decreases over time'),
                value: s.speedBasedScoring,
                onChanged: n.setSpeedBasedScoring,
              ),
              if (!s.speedBasedScoring)
                ListTile(
                  title: const Text('Fixed score per correct answer'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      controller: TextEditingController(text: '${s.fixedScore}'),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) {
                        final i = int.tryParse(v);
                        if (i != null) n.setFixedScore(i);
                      },
                    ),
                  ),
                ),
              SwitchListTile(
                title: const Text('Negative marking (−25 for wrong)'),
                value: s.negativeMarking,
                onChanged: n.setNegativeMarking,
              ),
            ],
          ),

          // ── Anti-cheat ─────────────────────────────────────────
          _Section(
            title: 'Anti-cheat / Test Mode',
            children: [
              SwitchListTile(
                title: const Text('Hide leaderboard during game'),
                value: s.hideLeaderboardDuringGame,
                onChanged: n.setHideLeaderboardDuringGame,
              ),
              SwitchListTile(
                title: const Text('Prevent answer review'),
                value: s.preventAnswerReview,
                onChanged: n.setPreventAnswerReview,
              ),
              SwitchListTile(
                title: const Text('One attempt only'),
                value: s.oneAttemptOnly,
                onChanged: n.setOneAttemptOnly,
              ),
            ],
          ),

          const SizedBox(height: 16),
          if (showContinue) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  final session = ref.read(gameSessionProvider);
                  if (session.quiz != null) {
                    ref.read(gameSessionProvider.notifier)
                        .startHostSession(session.quiz!, s);
                  }
                  context.push('/host/lobby');
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.answerBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: AppText.heading(fontSize: 18, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => ref.read(settingsProvider.notifier).reset(),
              child: Text('Reset to defaults', style: AppText.body(color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title,
                style: AppText.heading(fontSize: 14, color: AppColors.primaryTeal)),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
