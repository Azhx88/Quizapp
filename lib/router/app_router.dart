import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/ui/home/home_screen.dart';
import 'package:quizzapp/ui/library/quiz_library_screen.dart';
import 'package:quizzapp/ui/library/excel_import_screen.dart'; // Excel import
import 'package:quizzapp/data/services/excel_import_service.dart'; // Excel import
import 'package:quizzapp/ui/creator/quiz_creator_screen.dart';
import 'package:quizzapp/ui/creator/preview_screen.dart';
import 'package:quizzapp/ui/host/host_settings_screen.dart';
import 'package:quizzapp/ui/host/host_lobby_screen.dart';
import 'package:quizzapp/ui/host/report_screen.dart';
import 'package:quizzapp/ui/player/join_screen.dart';
import 'package:quizzapp/ui/player/waiting_room_screen.dart';
import 'package:quizzapp/ui/player/question_screen.dart';
import 'package:quizzapp/ui/player/results_screen.dart';
import 'package:quizzapp/ui/shared/mid_leaderboard_screen.dart';
import 'package:quizzapp/ui/history/game_history_screen.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/library', builder: (c, s) => const QuizLibraryScreen()),
      GoRoute(
        path: '/creator/:quizId',
        builder: (c, s) => QuizCreatorScreen(quizId: s.pathParameters['quizId']!),
      ),
      GoRoute(
        path: '/preview/:quizId',
        builder: (c, s) {
          final initial = s.extra is int ? s.extra as int : 0;
          return PreviewScreen(
            quizId: s.pathParameters['quizId']!,
            initialIndex: initial,
          );
        },
      ),
      GoRoute(path: '/host/settings', builder: (c, s) => const HostSettingsScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const HostSettingsScreen(showContinue: false)),
      GoRoute(path: '/host/lobby', builder: (c, s) => const HostLobbyScreen()),
      GoRoute(path: '/join', builder: (c, s) => const JoinScreen()),
      GoRoute(path: '/waiting', builder: (c, s) => const WaitingRoomScreen()),
      GoRoute(path: '/question', builder: (c, s) => const QuestionScreen()),
      GoRoute(path: '/mid-leaderboard', builder: (c, s) => const MidLeaderboardScreen()),
      GoRoute(path: '/results', builder: (c, s) => const ResultsScreen()),
      GoRoute(path: '/report', builder: (c, s) => const ReportHostScreen()),
      GoRoute(path: '/history', builder: (c, s) => const GameHistoryScreen()),
      // Excel import preview route — receives ExcelImportResult via extra.
      GoRoute(
        path: '/import-preview',
        builder: (c, s) => ExcelImportScreen(
          importResult: s.extra as ExcelImportResult,
        ),
      ),
    ],
  );
});
