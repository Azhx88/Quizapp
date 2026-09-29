import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/network/nsd_helper.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/network_provider.dart';
import 'package:quizzapp/providers/settings_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/confirm_exit.dart';
import 'package:quizzapp/utils/question_media.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _serverStarted = false;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _initHost();
  }

  Future<void> _initHost() async {
    final net = ref.read(networkServiceProvider);
    final nsd = ref.read(nsdHelperProvider);
    final session = ref.read(gameSessionProvider);

    await net.startHost();
    _localIp = await nsd.getLocalIpAddress();
    if (session.pin != null) {
      await nsd.startAdvertising('Quizapp', int.tryParse(session.pin!) ?? 0);
    }
    if (mounted) setState(() => _serverStarted = true);

    net.messages.listen((msg) {
      if (msg is JoinMessage) {
        // Tag the most recently connected unnamed socket with this name so we
        // can later map name → address for kick/lookup.
        final unnamed = net.clients.values.where((c) => c.name == null).toList();
        if (unnamed.isNotEmpty) {
          unnamed.last.name = msg.name;
          unnamed.last.avatarId = msg.avatarId;
        }
        final ps = PlayerScore(name: msg.name, avatarId: msg.avatarId);
        ref.read(gameSessionProvider.notifier).addPlayer(ps);
        final players = ref.read(gameSessionProvider).players;
        // Coalesce bursts of joins into a single broadcast every ~250ms.
        net.scheduleBroadcastPlayerList(
          players.map((p) => p.toJson()).toList(),
        );
      }
    });
  }

  @override
  void dispose() {
    NsdHelper.instance.stopAll();
    super.dispose();
  }

  void _startGame() {
    final net = ref.read(networkServiceProvider);
    final settings = ref.read(settingsProvider);
    // Make sure any pending player-list broadcasts go out before we start.
    net.flushPendingBroadcasts();
    net.sendToAll(SettingsSyncMessage(settings: settings.toJson()));
    net.sendToAll(GameStartingMessage(countdown: 3));
    context.pushReplacement('/question');
    _sendNextQuestion();
  }

  Future<void> _sendNextQuestion() async {
    final session = ref.read(gameSessionProvider);
    final net = ref.read(networkServiceProvider);
    final q = session.currentQuestion;
    if (q == null) return;
    final data = await QuestionMedia.toTransportableMap(q);
    net.sendToAll(QuestionMessage(
      slideType: q.slideType.name,
      data: data,
      index: session.currentQuestionIndex,
      total: session.quiz!.questions.length,
      timeLimit: session.settings.timePerQuestion,
    ));
  }

  void _kickPlayer(String name) {
    final net = ref.read(networkServiceProvider);
    // Find the connected socket for this name and disconnect it. The
    // PlayerKickedMessage is sent via NetworkService.kickPlayer so the
    // client gets a definitive signal before the socket closes.
    final entry = net.clients.values.where((c) => c.name == name).toList();
    for (final c in entry) {
      net.kickPlayer(c.address);
    }
    ref.read(gameSessionProvider.notifier).removePlayer(name);
    // Push the updated list to remaining clients so their lobby tile counts
    // refresh immediately.
    final players = ref.read(gameSessionProvider).players;
    net.scheduleBroadcastPlayerList(
      players.map((p) => p.toJson()).toList(),
    );
  }

  void _sharePin() {
    final pin = ref.read(gameSessionProvider).pin ?? '';
    Clipboard.setData(ClipboardData(text: pin));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final players = session.players;
    final pin = session.pin ?? '------';
    final connectUrl = 'quizzap://join?ip=${_localIp ?? ''}&pin=$pin';
    final formattedPin = pin.length == 6
        ? '${pin.substring(0, 3)} ${pin.substring(3)}'
        : pin;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmLeave();
        if (ok && context.mounted) context.go('/library');
      },
      child: Scaffold(
      backgroundColor: AppColors.questionBg,
      appBar: AppBar(
        backgroundColor: AppColors.questionBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          tooltip: 'Back to home',
          onPressed: () async {
            final ok = await _confirmLeave();
            if (ok && context.mounted) context.go('/');
          },
        ),
        title: Text('Host Lobby',
            style: AppText.heading(fontSize: 20, color: Colors.white)),
        centerTitle: true,
      ),
      body: !_serverStarted
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // PIN + QR section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${session.quiz?.title ?? 'Quiz'} - Round 1',
                    style: AppText.heading(fontSize: 24, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // PIN section
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Join PIN',
                                  style: AppText.body(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  )),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _sharePin,
                                child: Text(
                                  formattedPin,
                                  style: AppText.heading(
                                    fontSize: 48,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // QR code
                      if (_localIp != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: connectUrl,
                            version: QrVersions.auto,
                            size: 100,
                            backgroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),

                // Players header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Center(
                    child: Text('${players.length} Players joined',
                        style: AppText.heading(
                          color: Colors.white,
                          fontSize: 18,
                        )),
                  ),
                ),

                // Players grid
                Expanded(
                  child: players.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('👥', style: TextStyle(fontSize: 52)),
                              SizedBox(height: 14),
                              Text('Share the PIN to invite players',
                                  style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
                              SizedBox(height: 6),
                              Text('Long-press a player card to kick',
                                  style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 12)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: players.length,
                          itemBuilder: (ctx, i) {
                            final p = players[i];
                            return GestureDetector(
                              onLongPress: () => _kickPlayer(p.name),
                              child: Column(
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _startGame,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text('Start Game',
                                  style: AppText.heading(
                                    color: Colors.white,
                                    fontSize: 18,
                                  )),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _sharePin,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.ios_share, color: Colors.white),
                                const SizedBox(width: 8),
                                Text('Share PIN',
                                    style: AppText.heading(
                                      color: Colors.white,
                                      fontSize: 18,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final ok = await confirmExit(
      context,
      title: 'Close the lobby?',
      message:
          'Players who already joined will be disconnected. You can re-host this quiz from the library.',
      exitLabel: 'Close',
      cancelLabel: 'Stay',
    );
    if (ok) {
      try {
        ref.read(networkServiceProvider).dispose();
      } catch (_) {}
      ref.read(gameSessionProvider.notifier).reset();
    }
    return ok;
  }
}
