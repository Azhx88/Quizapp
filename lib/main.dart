import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/app.dart';
import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/seed/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.instance;
  await db.init();
  await SeedData.seedIfEmpty(db);
  await SeedData.ensureDemoMix(db);
  runApp(const ProviderScope(child: QuizZapApp()));
}
