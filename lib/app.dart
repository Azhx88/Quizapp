import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzapp/router/app_router.dart';
import 'package:quizzapp/utils/app_colors.dart';

class QuizZapApp extends ConsumerWidget {
  const QuizZapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Quizapp',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.appBackground,
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.fredoka(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.cardBg,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE8E3DA),
        ),
      ),
      themeMode: ThemeMode.light,
    );
  }
}
