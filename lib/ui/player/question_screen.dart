import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/network_provider.dart';
import 'package:quizzapp/ui/shared/countdown_ring.dart';
import 'package:quizzapp/ui/shared/result_burst_overlay.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/constants.dart';
import 'package:quizzapp/utils/haptic_utils.dart';
import 'package:quizzapp/utils/screen_security.dart';
import 'package:quizzapp/utils/confirm_exit.dart';
import 'package:quizzapp/utils/question_media.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Timer? _revealTimer;
  int _timeLeft = 30;
  int _totalTime = 30;
  int _elapsed = 0;

  late AnimationController _shakeCtrl;
  late AnimationController _bounceCtrl;

  final Set<int> _selectedOptions = {};

  // Stable shuffled option order — computed once per question, never on rebuild.
  List<String> _shuffledOptions = [];

  // Host-side counter: how many players have submitted an answer this question.
  int _answeredCount = 0;

  // Guard: ensures reveal is triggered at most once per question.
  bool _revealTriggered = false;

  // Forfeit flag — when true, the next reveal is treated as 0 points
  // regardless of negativeMarking (player switched apps mid-question).
  bool _forfeited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenSecurity.enable();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _initOptions();
    _listenMessages();
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `paused` (Android home/recents) and `hidden` (newer Flutter)  mean the
    // user actually left the app. `inactive` fires for transient interruptions
    // like a notification-shade pull or an incoming-call ringing screen, which
    // we don't want to penalise.
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden) {
      return;
    }
    try {
      final session = ref.read(gameSessionProvider);
      if (!session.isActive || session.isHost) return;
      final q = session.currentQuestion;
      if (q == null || q.slideType == SlideType.infoSlide) return;
      final ans = session.answerState;
      if (ans.hasAnswered || ans.isRevealed) return;
      _forfeited = true;
      _submitAnswer(null);
    } catch (_) {
      // Never let a lifecycle callback bubble — an exception here would
      // crash the app while the user is just switching to another app.
    }
  }

  // Build the stable answer-option list for the current question.
  void _initOptions() {
    final session = ref.read(gameSessionProvider);
    final q = session.currentQuestion;
    if (q == null) return;
    if (q.slideType != SlideType.buttons && q.slideType != SlideType.checkboxes) {
      _shuffledOptions = [];
      return;
    }
    final all = [
      ...List<String>.from(q.correctAnswers),
      ...List<String>.from(q.falseAnswers),
    ].where((s) => s.isNotEmpty).toList();
    if (session.settings.shuffleAnswerOptions) all.shuffle();
    _shuffledOptions = all;
  }

  void _startTimer() {
    final session = ref.read(gameSessionProvider);
    _totalTime = session.isHost
        ? session.settings.timePerQuestion
        : (session.receivedTimeLimit ?? session.settings.timePerQuestion);
    _timeLeft = _totalTime;
    _elapsed = 0;
    final startMs = DateTime.now().millisecondsSinceEpoch;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      final now = DateTime.now().millisecondsSinceEpoch;
      _elapsed = now - startMs;
      setState(() =>
          _timeLeft = (_totalTime - _elapsed ~/ 1000).clamp(0, _totalTime));
      if (_timeLeft == 0) { t.cancel(); _onTimeout(); }
    });
  }

  void _listenMessages() {
    ref.listenManual(networkMessagesProvider, (_, next) {
      next.whenData((msg) {
        if (msg is AnswerMessage) {
          if (ref.read(gameSessionProvider).isHost) {
            setState(() => _answeredCount++);
            _checkAllAnswered();
          }
        } else if (msg is PlayerScoreUpdateMessage) {
          if (ref.read(gameSessionProvider).isHost) {
            ref.read(gameSessionProvider.notifier).updatePlayerScore(
              name: msg.name,
              score: msg.score,
              correctCount: msg.correctCount,
              bestStreak: msg.bestStreak,
              streak: msg.streak,
            );
          }
        } else if (msg is RevealAnswerMessage) {
          if (!ref.read(gameSessionProvider).isHost) {
            _onReveal();
          }
        } else if (msg is LeaderboardMessage) {
          if (mounted) context.push('/mid-leaderboard');
        } else if (msg is QuestionMessage) {
          final q = Question.fromMap(msg.data);
          ref.read(gameSessionProvider.notifier).receiveQuestion(q, timeLimit: msg.timeLimit);
          _selectedOptions.clear();
          _forfeited = false;
          setState(() {
            _answeredCount = 0;
            _revealTriggered = false;
            _initOptions();
          });
          _startTimer();
        } else if (msg is PlayerKickedMessage) {
          if (!ref.read(gameSessionProvider).isHost) {
            ref.read(gameSessionProvider.notifier).reset();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You were removed by the host.')),
              );
              context.go('/');
            }
          }
        } else if (msg is GameEndMessage) {
          ref.read(gameSessionProvider.notifier).updateScores(msg.leaderboard);
          if (mounted) context.pushReplacement('/results');
        }
      });
    });
  }

  void _onTimeout() {
    if (ref.read(gameSessionProvider).isHost) {
      _triggerReveal();
      return;
    }
    final ans = ref.read(gameSessionProvider).answerState;
    if (ans.hasAnswered || ans.isRevealed) return;
    _submitAnswer(null);
  }

  // Host-only: trigger reveal once, broadcast to clients, start auto-advance.
  void _triggerReveal() {
    if (_revealTriggered) return;
    _revealTriggered = true;
    _timer?.cancel();
    ref.read(gameSessionProvider.notifier).revealAnswerUI();
    ref.read(networkServiceProvider).sendToAll(RevealAnswerMessage());
    _revealTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _onNextQuestion();
    });
  }

  // Host-only: called after each answer arrives to check if all players answered.
  void _checkAllAnswered() {
    if (_revealTriggered) return;
    final session = ref.read(gameSessionProvider);
    if (session.players.isNotEmpty && _answeredCount >= session.players.length) {
      _triggerReveal();
    }
  }

  // Client-only: called when RevealAnswerMessage arrives.
  void _onReveal() {
    _timer?.cancel();
    final session = ref.read(gameSessionProvider);
    if (!session.answerState.hasAnswered) {
      // Player ran out of time — force a null (wrong) submission.
      ref.read(gameSessionProvider.notifier).submitAnswer(null);
      _evaluateLocally(null);
    }
    final ans = ref.read(gameSessionProvider).answerState;
    if (ans.isCorrect == true) {
      HapticUtils.correctAnswer();
      _bounceCtrl.forward(from: 0);
    } else {
      HapticUtils.wrongAnswer();
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
    }
    ref.read(gameSessionProvider.notifier).revealAnswerUI();
  }

  void _submitAnswer(dynamic answer) {
    final session = ref.read(gameSessionProvider);
    if (session.answerState.hasAnswered) return;
    _timer?.cancel();
    ref.read(gameSessionProvider.notifier).submitAnswer(answer);

    _evaluateLocally(answer);

    // Clients report their score to the host.
    if (session.isClient) {
      final q = session.currentQuestion;
      if (q != null) {
        final net = ref.read(networkServiceProvider);
        net.sendToHost(AnswerMessage(
          questionId: q.id,
          answer: answer,
          timeTaken: _elapsed,
        ));
        final updated = ref.read(gameSessionProvider).localPlayer;
        if (updated != null) {
          net.sendToHost(PlayerScoreUpdateMessage(
            name: updated.name,
            score: updated.score,
            correctCount: updated.correctCount,
            bestStreak: updated.bestStreak,
            streak: updated.streak,
          ));
        }
      }
    }
  }

  void _evaluateLocally(dynamic answer) {
    final session = ref.read(gameSessionProvider);
    final q = session.currentQuestion;
    if (q == null) return;

    bool correct = false;
    switch (q.slideType) {
      case SlideType.buttons:
        correct = q.correctAnswers.isNotEmpty && answer == q.correctAnswers.first;
      case SlideType.checkboxes:
        final selected = (answer as List?)?.cast<String>() ?? [];
        correct = selected.toSet().containsAll(q.correctAnswers.toSet()) &&
            q.correctAnswers.toSet().containsAll(selected.toSet());
      case SlideType.reorder:
        correct = answer.toString() == q.orderedItems.join(',');
      case SlideType.range:
        final v = (answer as num?)?.toDouble() ?? 0;
        if (q.requireExactAnswer) {
          correct = v == q.correctValue;
        } else {
          final range = (q.maxValue ?? 100) - (q.minValue ?? 0);
          correct = range == 0 || ((v - (q.correctValue ?? 0)).abs() / range) < 0.1;
        }
      case SlideType.typeAnswer:
        correct = (answer as String?)?.trim().toLowerCase() ==
            q.typeAnswer?.trim().toLowerCase();
      case SlideType.infoSlide:
        correct = true;
    }

    final pts = correct
        ? session.computeScore(timeTaken: _elapsed, timeLimit: _totalTime * 1000)
        : (_forfeited
            ? 0
            : (session.settings.negativeMarking ? -kWrongPenalty : 0));

    ref.read(gameSessionProvider.notifier).revealAnswer(
      correct: correct,
      points: pts,
      correctAnswer: q.correctAnswers.isNotEmpty ? q.correctAnswers.first : q.correctValue,
      funFact: q.funFact,
    );
  }

  Future<void> _onNextQuestion() async {
    _revealTimer?.cancel();
    _revealTimer = null;
    _revealTriggered = false;

    ref.read(gameSessionProvider.notifier).advanceQuestion();
    final nextSession = ref.read(gameSessionProvider);
    final nextQ = nextSession.currentQuestion;
    final net = ref.read(networkServiceProvider);
    if (nextQ == null) {
      net.sendToAll(GameEndMessage(
        leaderboard: nextSession.players.map((p) => p.toJson()).toList(),
        stats: {},
      ));
      if (mounted) context.go('/results');
    } else {
      final data = await QuestionMedia.toTransportableMap(nextQ);
      net.sendToAll(QuestionMessage(
        slideType: nextQ.slideType.name,
        data: data,
        index: nextSession.currentQuestionIndex,
        total: nextSession.quiz!.questions.length,
        timeLimit: nextSession.settings.timePerQuestion,
      ));
      _selectedOptions.clear();
      _forfeited = false;
      if (mounted) {
        setState(() {
          _answeredCount = 0;
          _initOptions();
        });
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenSecurity.disable();
    _timer?.cancel();
    _revealTimer?.cancel();
    _shakeCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final q = session.currentQuestion;
    final ans = session.answerState;

    if (q == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (q.slideType == SlideType.infoSlide) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final wasHost = ref.read(gameSessionProvider).isHost;
          final ok = await _confirmAndExit();
          if (ok && context.mounted) context.go(wasHost ? '/library' : '/');
        },
        child: _InfoSlideView(
          question: q.question,
          body: q.funFact ?? '',
          isHost: session.isHost,
          onNext: session.isHost ? _onNextQuestion : () {},
        ),
      );
    }

    final totalQs = session.quiz?.questions.length ?? 0;
    final isLastQuestion = totalQs > 0 && session.currentQuestionIndex >= totalQs - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final wasHost = ref.read(gameSessionProvider).isHost;
        final ok = await _confirmAndExit();
        if (ok && mounted) context.go(wasHost ? '/library' : '/');
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Stack(
        children: [
        SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            _TopBar(
              streak: session.localPlayer?.streak ?? 0,
              qIndex: session.currentQuestionIndex + 1,
              total: totalQs,
              score: session.localPlayer?.score ?? 0,
              isHost: session.isHost,
            ),

            const SizedBox(height: 16),

            // ── Circular timer ────────────────────────────────────
            CountdownRing(timeLeft: _timeLeft, totalTime: _totalTime, size: 130),

            const SizedBox(height: 20),

            // ── Optional image ────────────────────────────────────
            if (q.mediaPath != null && q.mediaPath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: QuestionMedia.render(q.mediaPath, height: 180),
                ),
              ),
            if (q.mediaPath != null && q.mediaPath!.isNotEmpty)
              const SizedBox(height: 14),

            // ── Question card ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: Offset.zero, end: const Offset(0.05, 0))
                    .animate(CurvedAnimation(
                        parent: _shakeCtrl, curve: Curves.elasticIn)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hardShadow, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.hardShadow,
                          offset: Offset(4, 4),
                          blurRadius: 0),
                    ],
                  ),
                  child: Text(
                    q.question,
                    style: AppText.heading(
                      fontSize: 22,
                      color: AppColors.textDark,
                    ).copyWith(height: 1.35),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ── Answer widget (players) / Status widget (host) ────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: _buildAnswerWidget(q, ans, session),
            ),

            // ── Fun fact & result — only shown after reveal ───────
            if (!session.isHost && ans.isRevealed && ans.funFact != null && ans.funFact!.isNotEmpty)
              _FunFactBanner(fact: ans.funFact!),

            if (!session.isHost && ans.isRevealed)
              _ResultBanner(
                isCorrect: ans.isCorrect,
                points: ans.pointsAwarded,
                streak: session.localPlayer?.streak ?? 0,
              ),

            // ── Host: Next button — shown after reveal ─────────────
            if (session.isHost && ans.isRevealed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: _onNextQuestion,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hardShadow, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.hardShadow,
                            offset: Offset(4, 4),
                            blurRadius: 0),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastQuestion ? 'Show Results' : 'Next ›',
                          style: AppText.heading(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
        if (!session.isHost)
          ResultBurst(
            visible: ans.isRevealed,
            isCorrect: ans.isCorrect,
          ),
        ],
      ),
      ),
    );
  }

  Future<bool> _confirmAndExit() async {
    final session = ref.read(gameSessionProvider);
    final ok = await confirmExit(
      context,
      title: 'Leave the game?',
      message: session.isHost
          ? 'Leaving will end the game for all players. This cannot be undone.'
          : 'Leaving will forfeit your remaining answers and disconnect you from the game.',
      exitLabel: 'Leave',
      cancelLabel: 'Stay',
    );
    if (ok) {
      ref.read(gameSessionProvider.notifier).reset();
    }
    return ok;
  }

  Widget _buildAnswerWidget(Question q, AnswerState ans, GameSessionState session) {
    if (session.isHost) {
      return _HostStatusView(
        answeredCount: _answeredCount,
        totalPlayers: session.players.length,
        isRevealed: ans.isRevealed,
      );
    }

    switch (q.slideType) {
      case SlideType.buttons:
        final opts = _shuffledOptions.isNotEmpty
            ? _shuffledOptions
            : [
                ...List<String>.from(q.correctAnswers),
                ...List<String>.from(q.falseAnswers),
              ].where((s) => s.isNotEmpty).toList();
        return _ButtonsWidget(
          options: opts,
          selectedAnswer: ans.selectedAnswer as String?,
          correctAnswer: ans.isRevealed
              ? (q.correctAnswers.isNotEmpty ? q.correctAnswers.first : null)
              : null,
          hasAnswered: ans.hasAnswered,
          onTap: (ans.hasAnswered || ans.isRevealed) ? null : (v) => _submitAnswer(v),
        );

      case SlideType.checkboxes:
        final opts = _shuffledOptions.isNotEmpty
            ? _shuffledOptions
            : [
                ...List<String>.from(q.correctAnswers),
                ...List<String>.from(q.falseAnswers),
              ].where((s) => s.isNotEmpty).toList();
        return _CheckboxesWidget(
          options: opts,
          selected: _selectedOptions,
          hasAnswered: ans.hasAnswered,
          isRevealed: ans.isRevealed,
          correctAnswers: List<String>.from(q.correctAnswers),
          onSubmit: ans.hasAnswered
              ? null
              : () => _submitAnswer(_selectedOptions.map((i) => opts[i]).toList()),
          onToggle: ans.hasAnswered
              ? null
              : (i) => setState(() {
                    if (_selectedOptions.contains(i)) {
                      _selectedOptions.remove(i);
                    } else {
                      _selectedOptions.add(i);
                    }
                  }),
        );

      case SlideType.reorder:
        return _ReorderWidget(
          items: List<String>.from(q.orderedItems),
          hasAnswered: ans.hasAnswered,
          onSubmit: ans.hasAnswered ? null : (o) => _submitAnswer(o.join(',')),
        );

      case SlideType.range:
        return _RangeWidget(
          min: q.minValue ?? 0,
          max: q.maxValue ?? 100,
          unit: q.unit,
          hasAnswered: ans.hasAnswered,
          correctValue: ans.isRevealed ? q.correctValue : null,
          onSubmit: ans.hasAnswered ? null : (v) => _submitAnswer(v),
        );

      case SlideType.typeAnswer:
        return _TypeAnswerWidget(
          hasAnswered: ans.hasAnswered,
          onSubmit: ans.hasAnswered ? null : (v) => _submitAnswer(v),
        );

      case SlideType.infoSlide:
        return const SizedBox();
    }
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int streak, qIndex, total, score;
  final bool isHost;
  const _TopBar({
    required this.streak,
    required this.qIndex,
    required this.total,
    required this.score,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hardShadow, width: 1.5),
            ),
            child: Text(
              isHost
                  ? 'HOST'
                  : (streak >= kStreakThreshold ? '🔥 $streak Streak' : '⚡ Ready'),
              style: AppText.body(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          const Spacer(),
          if (total > 0)
            Text(
              'Q$qIndex/$total',
              style: AppText.heading(fontSize: 16, color: AppColors.textDark),
            ),
          const Spacer(),
          if (!isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hardShadow, width: 1.5),
              ),
              child: Text(
                '$score pts',
                style: AppText.body(fontSize: 13, color: AppColors.textDark),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Host status panel ────────────────────────────────────────────────────────

class _HostStatusView extends StatelessWidget {
  final int answeredCount;
  final int totalPlayers;
  final bool isRevealed;

  const _HostStatusView({
    required this.answeredCount,
    required this.totalPlayers,
    required this.isRevealed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hardShadow, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.hardShadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRevealed ? Icons.check_circle_rounded : Icons.people_rounded,
            color: isRevealed ? AppColors.answerGreen : AppColors.primaryTeal,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            '$answeredCount / $totalPlayers',
            style: AppText.heading(fontSize: 42, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            isRevealed ? 'Revealed — advancing soon…' : 'players answered',
            style: AppText.body(fontSize: 15, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Multiple choice (2×2 grid) ───────────────────────────────────────────────

class _ButtonsWidget extends StatelessWidget {
  final List<String> options;
  final String? selectedAnswer;
  final String? correctAnswer;
  final bool hasAnswered;
  final void Function(String)? onTap;

  const _ButtonsWidget({
    required this.options,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.hasAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = options.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final opt = items[i];
        Color base = AppColors.answerColors[i % AppColors.answerColors.length];
        IconData? icon;

        if (correctAnswer != null) {
          // Revealed state: show correct/wrong colors.
          if (opt == correctAnswer) {
            base = AppColors.answerGreen;
            icon = Icons.check_circle_rounded;
          } else if (opt == selectedAnswer) {
            base = AppColors.answerRed;
            icon = Icons.cancel_rounded;
          } else {
            base = base.withValues(alpha: 0.35);
          }
        } else if (hasAnswered) {
          // Answered but waiting for reveal: dim non-selected options.
          if (opt != selectedAnswer) {
            base = base.withValues(alpha: 0.35);
          }
        }

        return GestureDetector(
          onTap: onTap != null ? () => onTap!(opt) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hardShadow, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: AppColors.hardShadow,
                    offset: Offset(4, 4),
                    blurRadius: 0),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (icon != null)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Icon(icon, color: Colors.white70, size: 22),
                  ),
                if (hasAnswered && correctAnswer == null && opt == selectedAnswer)
                  const Positioned(
                    bottom: 8,
                    right: 10,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Result banner ────────────────────────────────────────────────────────────

class _ResultBanner extends StatelessWidget {
  final bool? isCorrect;
  final int points;
  final int streak;

  const _ResultBanner({
    required this.isCorrect,
    required this.points,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final correct = isCorrect == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: correct ? AppColors.answerGreen : AppColors.answerRed,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                correct ? 'Correct!' : 'Wrong!',
                style: AppText.heading(fontSize: 20, color: Colors.white),
              ),
              if (correct && points > 0)
                Text(
                  '+$points Points${streak >= kStreakThreshold ? ' · 🔥 Streak $streak' : ''}',
                  style: AppText.body(fontSize: 13, color: Colors.white70),
                ),
              if (!correct)
                Text(
                  streak >= kStreakThreshold ? 'Streak Reset' : '',
                  style: AppText.body(fontSize: 13, color: Colors.white70),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Checkboxes ───────────────────────────────────────────────────────────────

class _CheckboxesWidget extends StatelessWidget {
  final List<String> options;
  final Set<int> selected;
  final bool hasAnswered;
  final bool isRevealed;
  final List<String> correctAnswers;
  final VoidCallback? onSubmit;
  final void Function(int)? onToggle;

  const _CheckboxesWidget({
    required this.options,
    required this.selected,
    required this.hasAnswered,
    required this.isRevealed,
    required this.correctAnswers,
    required this.onSubmit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...options.asMap().entries.map((e) {
          final isSelected = selected.contains(e.key);
          final isCorrect = correctAnswers.contains(e.value);
          Color tileColor = Colors.white;
          if (isRevealed) {
            tileColor = isCorrect
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE);
          } else if (isSelected) {
            tileColor = const Color(0xFFE3F2FD);
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRevealed
                    ? (isCorrect ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))
                    : (isSelected ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0)),
                width: 1.5,
              ),
            ),
            child: CheckboxListTile(
              title: Text(e.value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
              value: isSelected,
              activeColor: const Color(0xFF2196F3),
              onChanged: onToggle != null ? (_) => onToggle!(e.key) : null,
            ),
          );
        }),
        const SizedBox(height: 10),
        if (!hasAnswered)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: selected.isEmpty ? null : onSubmit,
              child: const Text('Submit Answers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

// ── Reorder ──────────────────────────────────────────────────────────────────

class _ReorderWidget extends StatefulWidget {
  final List<String> items;
  final bool hasAnswered;
  final void Function(List<String>)? onSubmit;

  const _ReorderWidget({
    required this.items,
    required this.hasAnswered,
    required this.onSubmit,
  });

  @override
  State<_ReorderWidget> createState() => _ReorderWidgetState();
}

class _ReorderWidgetState extends State<_ReorderWidget> {
  late List<String> _current;

  @override
  void initState() {
    super.initState();
    _current = List<String>.from(widget.items)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: widget.hasAnswered
              ? (_, __) {}
              : (o, n) => setState(() {
                    final item = _current.removeAt(o);
                    _current.insert(n > o ? n - 1 : n, item);
                  }),
          children: _current
              .asMap()
              .entries
              .map((e) => Container(
                    key: ValueKey(e.value),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF4ECDC4),
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(e.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50))),
                      trailing: const Icon(Icons.drag_handle_rounded,
                          color: Color(0xFFBDC3C7)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        if (!widget.hasAnswered)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: () => widget.onSubmit!(_current),
              child: const Text('Submit Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

// ── Range ────────────────────────────────────────────────────────────────────

class _RangeWidget extends StatefulWidget {
  final double min, max;
  final String? unit;
  final bool hasAnswered;
  final double? correctValue;
  final void Function(double)? onSubmit;

  const _RangeWidget({
    required this.min,
    required this.max,
    required this.unit,
    required this.hasAnswered,
    required this.correctValue,
    required this.onSubmit,
  });

  @override
  State<_RangeWidget> createState() => _RangeWidgetState();
}

class _RangeWidgetState extends State<_RangeWidget> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = (widget.min + widget.max) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final safeMax = widget.max == widget.min ? widget.min + 1 : widget.max;
    final label = widget.unit != null
        ? '${_value.toStringAsFixed(1)} ${widget.unit}'
        : _value.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hardShadow, width: 2),
        boxShadow: const [
          BoxShadow(
              color: AppColors.hardShadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C3E50))),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4ECDC4),
              thumbColor: const Color(0xFF4ECDC4),
              overlayColor: const Color(0xFF4ECDC4).withAlpha(50),
              inactiveTrackColor: const Color(0xFFE0E0E0),
            ),
            child: Slider(
              min: widget.min,
              max: safeMax,
              value: _value.clamp(widget.min, safeMax),
              onChanged: widget.hasAnswered ? null : (v) => setState(() => _value = v),
            ),
          ),
          Row(children: [
            Text(widget.min.toStringAsFixed(0),
                style: const TextStyle(color: Color(0xFF9E9E9E))),
            const Spacer(),
            Text(widget.max.toStringAsFixed(0),
                style: const TextStyle(color: Color(0xFF9E9E9E))),
          ]),
          if (widget.hasAnswered && widget.correctValue != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Correct: ${widget.correctValue!.toStringAsFixed(1)}${widget.unit != null ? ' ${widget.unit}' : ''}',
                style: const TextStyle(
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ],
          if (!widget.hasAnswered) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => widget.onSubmit!(_value),
                child: const Text('Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Type answer ──────────────────────────────────────────────────────────────

class _TypeAnswerWidget extends StatefulWidget {
  final bool hasAnswered;
  final void Function(String)? onSubmit;

  const _TypeAnswerWidget({required this.hasAnswered, required this.onSubmit});

  @override
  State<_TypeAnswerWidget> createState() => _TypeAnswerWidgetState();
}

class _TypeAnswerWidgetState extends State<_TypeAnswerWidget> {
  // Persistent controller — re-creating it on every rebuild loses focus,
  // wipes typed text mid-keystroke, and can crash when onSubmitted fires
  // against a disposed controller.
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswered = widget.hasAnswered;
    final onSubmit = widget.onSubmit;
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          enabled: !hasAnswered,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
          decoration: InputDecoration(
            hintText: 'Type your answer…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: onSubmit,
        ),
        const SizedBox(height: 12),
        if (!hasAnswered)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: () => onSubmit!(_ctrl.text.trim()),
              child: const Text('Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

// ── Fun fact ─────────────────────────────────────────────────────────────────

class _FunFactBanner extends StatelessWidget {
  final String fact;
  const _FunFactBanner({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(fact,
                  style: const TextStyle(
                      color: Color(0xFF5D4037), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

// ── Info slide ───────────────────────────────────────────────────────────────

class _InfoSlideView extends StatelessWidget {
  final String question, body;
  final bool isHost;
  final VoidCallback onNext;

  const _InfoSlideView({
    required this.question,
    required this.body,
    required this.isHost,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.hardShadow, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.hardShadow,
                        offset: Offset(4, 4),
                        blurRadius: 0),
                  ],
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 52, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hardShadow, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.hardShadow,
                        offset: Offset(4, 4),
                        blurRadius: 0),
                  ],
                ),
                child: Column(
                  children: [
                    Text(question,
                        style: AppText.heading(
                            fontSize: 22, color: AppColors.textDark),
                        textAlign: TextAlign.center),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(body,
                          style: AppText.body(
                              fontSize: 15, color: AppColors.textMuted),
                          textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (isHost)
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hardShadow, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.hardShadow,
                            offset: Offset(4, 4),
                            blurRadius: 0),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue',
                            style: AppText.heading(
                                fontSize: 16, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                      ],
                    ),
                  ),
                )
              else
                Text('Waiting for host to continue…',
                    style:
                        AppText.body(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
