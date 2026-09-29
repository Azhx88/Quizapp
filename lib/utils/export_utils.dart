import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/data/models/quiz_model.dart';

Future<void> shareResultsCsv(String quizTitle, List<PlayerScore> players) async {
  final buf = StringBuffer();
  buf.writeln('QuizZap Report: $quizTitle');
  buf.writeln('Generated: ${DateTime.now().toString().substring(0, 16)}');
  buf.writeln();
  buf.writeln('Rank,Name,Score,Correct,Best Streak');
  players.asMap().forEach((i, p) {
    final name = '"${p.name.replaceAll('"', '""')}"';
    buf.writeln('${i + 1},$name,${p.score},${p.correctCount},${p.bestStreak}');
  });

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/quizzap_results.csv');
  await file.writeAsString(buf.toString());
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv')],
    subject: 'QuizZap Results – $quizTitle',
  );
}

/// Generates a detailed multi-section PDF report and shares it via the system
/// share sheet. Includes summary stats, score distribution bars, and a full
/// per-player table.
Future<void> shareResultsPdf({
  required String quizTitle,
  required List<PlayerScore> players,
  Quiz? quiz,
}) async {
  final sortedPlayers = [...players]
    ..sort((a, b) => b.score.compareTo(a.score));
  final totalQuestions = quiz?.questions.length ?? 0;
  final totalAnswered = sortedPlayers.fold<int>(0, (s, p) => s + p.correctCount);
  final possibleCorrect = sortedPlayers.length * totalQuestions;
  final overallAccuracy = possibleCorrect == 0
      ? 0.0
      : (totalAnswered / possibleCorrect) * 100;
  final averageScore = sortedPlayers.isEmpty
      ? 0.0
      : sortedPlayers.fold<int>(0, (s, p) => s + p.score) / sortedPlayers.length;
  final maxScore = sortedPlayers.isEmpty
      ? 1
      : sortedPlayers.map((p) => p.score).reduce((a, b) => a > b ? a : b);

  const teal = PdfColor.fromInt(0xFF4ECDC4);
  const dark = PdfColor.fromInt(0xFF2C3E50);
  const muted = PdfColor.fromInt(0xFF7F8C8D);
  const cardBg = PdfColor.fromInt(0xFFF8F5EE);

  final doc = pw.Document(title: 'QuizZap Report — $quizTitle');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: teal,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('QuizZap — Game Report',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(quizTitle,
                  style: const pw.TextStyle(
                      color: PdfColors.white, fontSize: 14)),
              pw.SizedBox(height: 2),
              pw.Text('Generated ${_fmtDate(DateTime.now())}',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
        pw.SizedBox(height: 18),

        // Summary cards
        pw.Row(children: [
          _summaryCard('Players', '${sortedPlayers.length}', teal, cardBg, dark),
          pw.SizedBox(width: 8),
          _summaryCard('Questions', '$totalQuestions', teal, cardBg, dark),
          pw.SizedBox(width: 8),
          _summaryCard(
              'Avg Score', averageScore.toStringAsFixed(0), teal, cardBg, dark),
          pw.SizedBox(width: 8),
          _summaryCard(
              'Accuracy',
              '${overallAccuracy.toStringAsFixed(1)}%',
              teal,
              cardBg,
              dark),
        ]),
        pw.SizedBox(height: 22),

        // Score distribution bars
        pw.Text('Score distribution',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold, color: dark)),
        pw.SizedBox(height: 8),
        if (sortedPlayers.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text('No players in this session.',
                style: pw.TextStyle(color: muted, fontSize: 12)),
          )
        else
          ...sortedPlayers.take(20).map((p) => _scoreBar(
              name: p.name,
              score: p.score,
              maxScore: maxScore,
              barColor: teal,
              labelColor: dark,
              mutedColor: muted)),
        if (sortedPlayers.length > 20)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
                'Showing top 20 of ${sortedPlayers.length} players. Full table below.',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: muted)),
          ),

        pw.SizedBox(height: 22),

        // Per-player table
        pw.Text('Final standings',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold, color: dark)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(36),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.5),
            4: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDEDED)),
              children: [
                _th('#'),
                _th('Player'),
                _th('Score'),
                _th('Correct'),
                _th('Best Streak'),
              ],
            ),
            ...sortedPlayers.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final highlight = i == 0
                  ? PdfColor.fromInt(0xFFFFF9C4)
                  : i.isEven
                      ? PdfColors.white
                      : PdfColor.fromInt(0xFFFAFAFA);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: highlight),
                children: [
                  _td('${i + 1}'),
                  _td(p.name),
                  _td('${p.score}', bold: i == 0),
                  _td('${p.correctCount}/$totalQuestions'),
                  _td('${p.bestStreak}'),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 22),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text('Generated by QuizZap',
              style: pw.TextStyle(
                  fontSize: 9, color: muted, fontStyle: pw.FontStyle.italic)),
        ),

        // Per-question section (if quiz available)
        if (quiz != null && quiz.questions.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          pw.Text('Questions in this quiz',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: dark)),
          pw.SizedBox(height: 8),
          ...quiz.questions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Q${i + 1}. ${q.question}',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: dark)),
                  if (q.correctAnswers.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Correct: ${q.correctAnswers.join(", ")}',
                        style: pw.TextStyle(
                            fontSize: 10, color: PdfColor.fromInt(0xFF27AE60))),
                  ],
                  if (q.funFact != null && q.funFact!.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Fun fact: ${q.funFact}',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: muted)),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final safeName = quizTitle.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final file = File('${dir.path}/quizzap_report_$safeName.pdf');
  await file.writeAsBytes(await doc.save());
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: 'QuizZap Report – $quizTitle',
  );
}

pw.Widget _summaryCard(
  String label,
  String value,
  PdfColor accent,
  PdfColor bg,
  PdfColor textColor,
) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: accent, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF7F8C8D))),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor)),
        ],
      ),
    ),
  );
}

pw.Widget _scoreBar({
  required String name,
  required int score,
  required int maxScore,
  required PdfColor barColor,
  required PdfColor labelColor,
  required PdfColor mutedColor,
}) {
  // Two flex slots: filled portion (barColor) + remainder (background).
  // The pdf widgets package has no FractionallySizedBox, so we use Row+Expanded
  // with integer flex weights derived from the ratio.
  final ratio = maxScore == 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
  final filledFlex = (ratio * 1000).round().clamp(0, 1000);
  final remainderFlex = (1000 - filledFlex).clamp(0, 1000);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 110,
          child: pw.Text(name,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(fontSize: 11, color: labelColor)),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 14,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFEEE9DD),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Row(children: [
              if (filledFlex > 0)
                pw.Expanded(
                  flex: filledFlex,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: barColor,
                      borderRadius: pw.BorderRadius.circular(7),
                    ),
                  ),
                ),
              if (remainderFlex > 0)
                pw.Expanded(flex: remainderFlex, child: pw.SizedBox()),
            ]),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: 50,
          child: pw.Text('$score',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: labelColor)),
        ),
      ],
    ),
  );
}

pw.Widget _th(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF2C3E50))),
    );

pw.Widget _td(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromInt(0xFF2C3E50))),
    );

String _fmtDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
