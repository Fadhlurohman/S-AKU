import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

void printReport(List<Transaction> transactions) async {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  final now = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now());

  // Load Unicode-compatible fonts — fallback to default if offline
  pw.Font? fontRegular, fontBold, fontItalic;
  try {
    fontRegular = await PdfGoogleFonts.nunitoRegular();
    fontBold = await PdfGoogleFonts.nunitoBold();
    fontItalic = await PdfGoogleFonts.nunitoItalic();
  } catch (_) {
    // Offline or failed — will use default PDF font
  }

  // Accent colors
  const green = PdfColor.fromInt(0xFF10B981);
  const red = PdfColor.fromInt(0xFFF43F5E);
  const headerBg = PdfColor.fromInt(0xFFF3F4F6);
  const textDark = PdfColor.fromInt(0xFF1F2937);
  const textGrey = PdfColor.fromInt(0xFF6B7280);
  const borderColor = PdfColor.fromInt(0xFFE5E7EB);

  double totalIncome = 0;
  double totalExpense = 0;

  final pdf = pw.Document();
  final theme = fontRegular != null
      ? pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        )
      : pw.ThemeData();


  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: theme,
      build: (context) {
        // Build table rows
        final rows = <pw.TableRow>[];

        // Header row
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: headerBg),
            children: [
              _cell('Tanggal', isHeader: true),
              _cell('Tipe', isHeader: true),
              _cell('Kategori', isHeader: true),
              _cell('Catatan', isHeader: true),
              _cell('Nominal', isHeader: true, align: pw.TextAlign.right),
            ],
          ),
        );

        // Data rows
        for (final tx in transactions) {
          final isIncome = tx.type == 'income';
          if (isIncome) {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
          }

          rows.add(
            pw.TableRow(
              children: [
                _cell(formatDate.format(tx.date)),
                _cell(isIncome ? 'Pemasukan' : 'Pengeluaran',
                    color: isIncome ? green : red),
                _cell(tx.category),
                _cell(tx.description),
                _cell(
                  '${isIncome ? '+' : '-'} ${formatCurrency.format(tx.amount)}',
                  color: isIncome ? green : red,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
          );
        }

        return [
          // Title
          pw.Text(
            'DompetGweh',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: green,
            ),
          ),
          pw.Text(
            '"Catat masuknya dikit, keluarnya banyak."',
            style: pw.TextStyle(fontSize: 11, color: textGrey, fontStyle: pw.FontStyle.italic),
          ),
          pw.Text(
            'Dicetak pada: $now',
            style: pw.TextStyle(fontSize: 9, color: textGrey),
          ),
          pw.SizedBox(height: 16),

          // Table
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
              4: const pw.FlexColumnWidth(2.5),
            },
            children: rows,
          ),
          pw.SizedBox(height: 20),

          // Summary
          pw.Divider(color: borderColor),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _summaryRow('Total Pemasukan', formatCurrency.format(totalIncome), green),
                _summaryRow('Total Pengeluaran', formatCurrency.format(totalExpense), red),
                pw.Divider(color: borderColor),
                _summaryRow(
                  'Selisih (Saldo)',
                  formatCurrency.format(totalIncome - totalExpense),
                  textDark,
                  bold: true,
                ),
              ],
            ),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: 'Laporan_DompetGweh_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
  );
}

// Helper: table cell
pw.Widget _cell(
  String text, {
  bool isHeader = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: isHeader ? 10 : 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? (isHeader ? const PdfColor.fromInt(0xFF374151) : const PdfColor.fromInt(0xFF1F2937)),
      ),
    ),
  );
}

// Helper: summary row
pw.Widget _summaryRow(String label, String value, PdfColor valueColor, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label:  ',
          style: pw.TextStyle(
            fontSize: 11,
            color: const PdfColor.fromInt(0xFF6B7280),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    ),
  );
}
