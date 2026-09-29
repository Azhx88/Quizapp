import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/network_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  int _selectedAvatar = 0;
  bool _connecting = false;
  String? _error;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    ref.read(nsdHelperProvider).startDiscovery();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect(String host) async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });

    final net = ref.read(networkServiceProvider);
    final ok = await net.connectToHost(host);
    if (!ok) {
      setState(() {
        _connecting = false;
        _error = 'Could not connect to $host';
      });
      return;
    }

    net.sendToHost(JoinMessage(
      name: _nameCtrl.text.trim(),
      avatarId: _selectedAvatar,
    ));

    final player = PlayerScore(name: _nameCtrl.text.trim(), avatarId: _selectedAvatar);
    ref.read(gameSessionProvider.notifier).startClientSession(player);

    if (mounted) context.pushReplacement('/waiting');
  }

  @override
  Widget build(BuildContext context) {
    final discovered = ref.watch(discoveredHostsProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          tooltip: 'Back to home',
          onPressed: () => context.go('/'),
        ),
        title: Text('Join a Game',
            style: AppText.heading(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  Text('Your Name', style: AppText.heading(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: AppText.body(),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: AppText.body(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primaryTeal),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.divider, width: 1),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 24),

                  // Avatar picker
                  Text('Choose Avatar', style: AppText.heading(fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: SvgAssets.avatars.length,
                    itemBuilder: (c, i) {
                      final isSel = i == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isSel ? AppColors.primaryPink : AppColors.hardShadow,
                                width: isSel ? 4 : 2),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              SvgAssets.avatars[i],
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tab toggle
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: AppText.body(fontWeight: FontWeight.w700, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: '🔍  Auto Discover'),
                        Tab(text: '🔢  Manual IP'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Auto discover tab
                        discovered.when(
                          loading: () => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.primaryTeal),
                                SizedBox(height: 12),
                                Text('Scanning for games…'),
                              ],
                            ),
                          ),
                          error: (_, __) => const Center(child: Text('Scan failed')),
                          data: (hosts) => hosts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('📡', style: TextStyle(fontSize: 36)),
                                      const SizedBox(height: 8),
                                      Text('No games found on this network',
                                          style: AppText.body(color: AppColors.textMuted)),
                                    ],
                                  ),
                                )
                              : ListView(
                                  children: hosts
                                      .map((h) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppColors.divider),
                                            ),
                                            child: ListTile(
                                              leading: const Text('🎮',
                                                  style: TextStyle(fontSize: 24)),
                                              title: Text(h.name,
                                                  style: AppText.heading(fontSize: 14)),
                                              subtitle: Text(h.address,
                                                  style: AppText.body(
                                                      fontSize: 12,
                                                      color: AppColors.textMuted)),
                                              trailing: GestureDetector(
                                                onTap: _connecting
                                                    ? null
                                                    : () => _connect(h.address),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryTeal,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text('Join',
                                                      style: AppText.heading(
                                                          color: Colors.white,
                                                          fontSize: 14)),
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                        ),

                        // Manual IP tab
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _ipCtrl,
                              style: AppText.body(),
                              decoration: InputDecoration(
                                hintText: '192.168.1.x',
                                hintStyle: AppText.body(color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.lan_rounded,
                                    color: AppColors.primaryTeal),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _connecting
                                  ? null
                                  : () => _connect(_ipCtrl.text.trim()),
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _connecting
                                      ? AppColors.textMuted
                                      : AppColors.primaryTeal,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: _connecting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : Text('Connect',
                                          style: AppText.heading(
                                            color: Colors.white,
                                            fontSize: 16,
                                          )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFE74C3C), size: 18),
                          const SizedBox(width: 8),
                          Text(_error!,
                              style:
                                  const TextStyle(color: Color(0xFFE74C3C))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Join Game pill button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: GestureDetector(
              onTap: _connecting
                  ? null
                  : () {
                      final hosts = discovered.value ?? [];
                      if (_tabCtrl.index == 0 && hosts.isNotEmpty) {
                        _connect(hosts.first.address);
                      } else if (_tabCtrl.index == 1 &&
                          _ipCtrl.text.trim().isNotEmpty) {
                        _connect(_ipCtrl.text.trim());
                      } else {
                        setState(() =>
                            _error = 'Select a game or enter an IP address');
                      }
                    },
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
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
                  child: _connecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Text('Join Game',
                                style: AppText.heading(
                                  color: Colors.white,
                                  fontSize: 22,
                                )),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
