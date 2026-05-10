import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfService {
  // ─── Public entry point ───────────────────────────────────────────────────
  static Future<void> generateAndShareHistoryPdf(
    BuildContext context,
    List<PredictionRecord> records,
  ) async {
    final pdf = pw.Document();

    // ── Fonts ────────────────────────────────────────────────────────────────
    final regularFont = await PdfGoogleFonts.interRegular();
    final boldFont    = await PdfGoogleFonts.interBold();
    final lightFont   = await PdfGoogleFonts.interLight();

    // ── Color palette ────────────────────────────────────────────────────────
    const primaryBlue  = PdfColor.fromInt(0xFF2D82F5);
    const bgColor      = PdfColor.fromInt(0xFFF4F6FA);
    const cardColor    = PdfColor.fromInt(0xFFFFFFFF);
    const headerColor  = PdfColor.fromInt(0xFF1A1A2E);
    const bodyText     = PdfColor.fromInt(0xFF374151);
    const mutedText    = PdfColor.fromInt(0xFF6B7280);
    const lowRisk      = PdfColor.fromInt(0xFF10B981);
    const medRisk      = PdfColor.fromInt(0xFFF59E0B);
    const highRisk     = PdfColor.fromInt(0xFFEF4444);

    PdfColor _riskColor(String level) {
      switch (level.toLowerCase()) {
        case 'low':    return lowRisk;
        case 'medium': return medRisk;
        default:       return highRisk;
      }
    }

    String _cholLevel(int v) {
      if (v == 1) return 'Normal';
      if (v == 2) return 'High';
      return 'Very High';
    }

    String _glucLevel(int v) => _cholLevel(v);

    // ── Header ────────────────────────────────────────────────────────────────
    pw.Widget _buildHeader() => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const pw.BoxDecoration(color: primaryBlue),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 44,
            height: 44,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Center(
              child: pw.Text(
                '♥',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 22,
                  color: primaryBlue,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CardioGuard',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Cardiovascular Disease Prediction Report',
                style: pw.TextStyle(
                  font: lightFont,
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xB3FFFFFF),
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated On',
                style: pw.TextStyle(
                  font: lightFont,
                  fontSize: 8,
                  color: const PdfColor.fromInt(0xB3FFFFFF),
                ),
              ),
              pw.Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // ── Summary strip ─────────────────────────────────────────────────────────
    pw.Widget _buildSummary() {
      final total = records.length;
      final highCount = records.where((r) =>
          r.riskLevel.toLowerCase() == 'high').length;
      final medCount  = records.where((r) =>
          r.riskLevel.toLowerCase() == 'medium').length;
      final lowCount  = records.where((r) =>
          r.riskLevel.toLowerCase() == 'low').length;

      pw.Widget _summaryTile(String label, String value, PdfColor color) =>
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 4),
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    label,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xB3FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          );

      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: pw.Row(
          children: [
            _summaryTile('Total Records', total.toString(), primaryBlue),
            _summaryTile('High Risk', highCount.toString(), highRisk),
            _summaryTile('Medium Risk', medCount.toString(), medRisk),
            _summaryTile('Low Risk', lowCount.toString(), lowRisk),
          ],
        ),
      );
    }

    // ── Table header ──────────────────────────────────────────────────────────
    pw.Widget _buildTableHeader() => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const pw.BoxDecoration(color: headerColor),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 3, child: pw.Text('Date & Time',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 2, child: pw.Text('BMI',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 2, child: pw.Text('Blood Pressure',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 2, child: pw.Text('Cholesterol',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 2, child: pw.Text('Glucose',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 2, child: pw.Text('Risk',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
          pw.Expanded(flex: 3, child: pw.Text('CVD Result',
              style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white))),
        ],
      ),
    );

    // ── Table row ─────────────────────────────────────────────────────────────
    pw.Widget _buildTableRow(PredictionRecord r, int index) {
      final riskColor = _riskColor(r.riskLevel);
      final isEven = index.isEven;

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: isEven ? cardColor : bgColor,
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    DateFormat('MMM d, yyyy').format(r.date),
                    style: pw.TextStyle(font: boldFont, fontSize: 8, color: bodyText),
                  ),
                  pw.Text(
                    DateFormat('h:mm a').format(r.date),
                    style: pw.TextStyle(font: lightFont, fontSize: 7, color: mutedText),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    r.bmi.toStringAsFixed(1),
                    style: pw.TextStyle(font: boldFont, fontSize: 8, color: bodyText),
                  ),
                  pw.Text(
                    r.bmiCategory,
                    style: pw.TextStyle(font: lightFont, fontSize: 7, color: mutedText),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                '${r.apHi}/${r.apLo}',
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: bodyText),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _cholLevel(r.cholesterol),
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: bodyText),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                _glucLevel(r.gluc),
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: bodyText),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: riskColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  r.riskLevel,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 7,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    r.prediction ? 'CVD Detected' : 'No CVD',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                      color: r.prediction ? highRisk : lowRisk,
                    ),
                  ),
                  pw.Text(
                    '${r.probability.toStringAsFixed(1)}% probability',
                    style: pw.TextStyle(font: lightFont, fontSize: 7, color: mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Footer ────────────────────────────────────────────────────────────────
    pw.Widget _buildFooter(pw.Context ctx) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CardioGuard — CVD Prediction Report',
            style: pw.TextStyle(font: lightFont, fontSize: 7, color: mutedText),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(font: lightFont, fontSize: 7, color: mutedText),
          ),
        ],
      ),
    );

    // ── Disclaimer card ───────────────────────────────────────────────────────
    pw.Widget _buildDisclaimer() => pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF3CD),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: medRisk, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('⚠ ',
              style: pw.TextStyle(font: boldFont, fontSize: 10, color: medRisk)),
          pw.Expanded(
            child: pw.Text(
              'This report is generated by the CardioGuard AI model for informational '
              'purposes only and does not constitute medical advice. Please consult a '
              'qualified healthcare professional for diagnosis and treatment.',
              style: pw.TextStyle(font: lightFont, fontSize: 7.5, color: bodyText),
            ),
          ),
        ],
      ),
    );

    // ── Build pages ───────────────────────────────────────────────────────────
    const rowsPerPage = 18;
    final pages = (records.length / rowsPerPage).ceil().clamp(1, double.infinity).toInt();

    for (int page = 0; page < pages; page++) {
      final start = page * rowsPerPage;
      final end   = (start + rowsPerPage).clamp(0, records.length);
      final chunk = records.sublist(start, end);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Column(
            children: [
              // header only on first page
              if (page == 0) _buildHeader(),
              if (page == 0) _buildSummary(),
              if (page == 0) _buildDisclaimer(),

              // section label
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Prediction History',
                      style: pw.TextStyle(
                          font: boldFont, fontSize: 13, color: headerColor),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      '${records.length} record${records.length == 1 ? '' : 's'}',
                      style: pw.TextStyle(
                          font: lightFont, fontSize: 9, color: mutedText),
                    ),
                  ],
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                child: _buildTableHeader(),
              ),

              ...chunk.asMap().entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTableRow(e.value, start + e.key),
                  )),

              pw.Spacer(),
              _buildFooter(ctx),
            ],
          ),
        ),
      );
    }

    // ── Share / save ──────────────────────────────────────────────────────────
    final fileName =
        'CardioGuard_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName,
    );
  }
}
