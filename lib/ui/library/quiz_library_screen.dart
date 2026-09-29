import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart'; // Excel import
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';
import 'package:quizzapp/data/services/excel_import_service.dart'; // Excel import
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/quiz_provider.dart';
import 'package:quizzapp/providers/settings_provider.dart';
import 'package:quizzapp/ui/shared/app_bottom_nav.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/svg_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuizLibraryScreen extends ConsumerStatefulWidget {
  const QuizLibraryScreen({super.key});

  @override
  ConsumerState<QuizLibraryScreen> createState() => _QuizLibraryScreenState();
}

class _QuizLibraryScreenState extends ConsumerState<QuizLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _createNewQuiz() {
    final id = const Uuid().v4();
    final quiz = Quiz(
      id: id,
      title: 'New Quiz',
      category: 'General',
      createdAt: DateTime.now(),
      questions: [
        Question(
          id: const Uuid().v4(),
          quizId: id,
          slideType: SlideType.buttons,
          question: '',
          correctAnswers: [''],
          falseAnswers: ['', ''],
        ),
      ],
    );
    ref.read(activeQuizProvider.notifier).load(quiz);
    context.push('/creator/$id');
  }

  // ── Import questions from an Excel file ──
  Future<void> _importFromExcel() async {
    try {
      // Open file picker filtered to Excel files only.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Load file bytes into memory.
      );

      if (result == null || result.files.isEmpty) return; // User cancelled.

      final file = result.files.first;
      if (file.bytes == null || file.bytes!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the selected file.'),
            backgroundColor: AppColors.answerRed,
          ),
        );
        return;
      }

      // Parse the Excel file.
      final importResult = ExcelImportService.parse(
        file.bytes!,
        file.name,
      );

      if (!mounted) return;

      // Navigate to the import preview screen.
      context.push('/import-preview', extra: importResult);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to parse Excel file: $e'),
          backgroundColor: AppColors.answerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = ref.watch(quizListProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewQuiz,
        backgroundColor: AppColors.primaryPink,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  ),
                  const Spacer(),
                  Text('Quiz Library', style: AppText.heading(fontSize: 22, color: AppColors.primaryTeal)),
                  const Spacer(),
                  // Import from Excel button.
                  IconButton(
                    onPressed: _importFromExcel,
                    icon: const Icon(Icons.file_upload_outlined, color: AppColors.primaryTeal),
                    tooltip: 'Import from Excel',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E3DA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: AppText.body(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search quizzes',
                    hintStyle: AppText.body(fontSize: 14, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),



            // Quiz grid
            Expanded(
              child: quizzes.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTeal)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  final filtered = list.where((q) {
                    final matchSearch = _searchQuery.isEmpty ||
                        q.title.toLowerCase().contains(_searchQuery) ||
                        q.category.toLowerCase().contains(_searchQuery);
                    final matchCat =
                        _selectedCategory == null || q.category == _selectedCategory;
                    return matchSearch && matchCat;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📭', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text('No quizzes found',
                              style: AppText.heading(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Tap + to create one',
                              style: AppText.body(color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _QuizGridCard(
                      quiz: filtered[i],
                      onHost: () {
                        final settings = ref.read(settingsProvider);
                        ref
                            .read(gameSessionProvider.notifier)
                            .startHostSession(filtered[i], settings);
                        context.push('/host/lobby');
                      },
                      onEdit: () {
                        ref.read(activeQuizProvider.notifier).load(filtered[i]);
                        context.push('/creator/${filtered[i].id}');
                      },
                      onDelete: () => _confirmDelete(context, ref, filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Quiz', style: AppText.heading(fontSize: 18)),
        content: Text('Delete "${quiz.title}"? This cannot be undone.',
            style: AppText.body()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppText.body(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(quizRepositoryProvider).delete(quiz.id);
              ref.invalidate(quizListProvider);
            },
            child: Text('Delete', style: AppText.body(color: AppColors.answerRed)),
          ),
        ],
      ),
    );
  }
}


// ─── Quiz Grid Card ───

class _QuizGridCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onHost;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuizGridCard({
    required this.quiz,
    required this.onHost,
    required this.onEdit,
    required this.onDelete,
  });

  String get _svgIcon {
    return SvgAssets.avatars[quiz.id.hashCode.abs() % SvgAssets.avatars.length];
  }

  Color get _tintColor {
    final colors = [
      const Color(0xFFFFF3E0), // warm orange tint
      const Color(0xFFE8F5E9), // green tint
      const Color(0xFFE3F2FD), // blue tint
      const Color(0xFFFCE4EC), // pink tint
      const Color(0xFFF3E5F5), // purple tint
    ];
    return colors[quiz.title.length % colors.length];
  }

  Color get _progressColor {
    final colors = [
      AppColors.primaryTeal,
      AppColors.chipActiveGold,
      AppColors.answerBlue,
      AppColors.primaryPink,
    ];
    return colors[quiz.title.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji top section
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _tintColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SvgPicture.string(
                      _svgIcon,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  // Question count badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Text(
                      '${quiz.questions.length} Qs',
                      style: AppText.body(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: AppText.heading(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.category}  •  ${quiz.questions.length} Qs',
                      style: AppText.body(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Progress bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _progressColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.7,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _progressColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.primaryTeal),
              title: Text('Host Game', style: AppText.body()),
              onTap: () {
                Navigator.pop(context);
                onHost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.answerBlue),
              title: Text('Edit', style: AppText.body()),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.answerRed),
              title: Text('Delete', style: AppText.body(color: AppColors.answerRed)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
