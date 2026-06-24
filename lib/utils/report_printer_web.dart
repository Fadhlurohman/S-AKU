// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

void printReport(List<Transaction> transactions) {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  final buffer = StringBuffer();
  buffer.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Laporan Transaksi DompetGweh</title>
  <style>
    body { font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 30px; color: #1f2937; line-height: 1.5; }
    h1 { color: #10B981; margin-bottom: 5px; font-weight: 800; }
    .slogan { font-style: italic; color: #6b7280; font-size: 13px; margin-bottom: 5px; }
    .timestamp { font-size: 11px; color: #9ca3af; margin-bottom: 30px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { border-bottom: 1px solid #e5e7eb; padding: 12px; text-align: left; font-size: 13px; }
    th { background-color: #f3f4f6; color: #374151; font-weight: bold; }
    .income { color: #10B981; font-weight: bold; }
    .expense { color: #ef4444; font-weight: bold; }
    .total-section { margin-top: 30px; text-align: right; font-size: 14px; font-weight: bold; border-top: 2px solid #e5e7eb; padding-top: 15px; line-height: 1.8; }
  </style>
</head>
<body>
  <h1>DompetGweh</h1>
  <div class="slogan">"Catat masuknya dikit, keluarnya banyak."</div>
  <div class="timestamp">Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}</div>
  <table>
    <thead>
      <tr>
        <th>Tanggal</th>
        <th>Tipe</th>
        <th>Kategori</th>
        <th>Catatan</th>
        <th>Nominal</th>
      </tr>
    </thead>
    <tbody>
  ''');

  double totalIncome = 0;
  double totalExpense = 0;

  for (final tx in transactions) {
    final isIncome = tx.type == 'income';
    if (isIncome) {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
    }

    final typeLabel = isIncome ? 'Pemasukan' : 'Pengeluaran';
    final amountClass = isIncome ? 'income' : 'expense';
    final amountPrefix = isIncome ? '+' : '-';
    
    buffer.write('''
      <tr>
        <td>${formatDate.format(tx.date)}</td>
        <td>$typeLabel</td>
        <td>${tx.category}</td>
        <td>${tx.description}</td>
        <td class="$amountClass">$amountPrefix ${formatCurrency.format(tx.amount)}</td>
      </tr>
    ''');
  }

  buffer.write('''
    </tbody>
  </table>
  <div class="total-section">
    Total Pemasukan: ${formatCurrency.format(totalIncome)}<br>
    Total Pengeluaran: ${formatCurrency.format(totalExpense)}<br>
    Selisih (Saldo): ${formatCurrency.format(totalIncome - totalExpense)}
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 500);
    }
  </script>
</body>
</html>
  ''');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
