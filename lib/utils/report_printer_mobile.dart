import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

void printReport(List<Transaction> transactions) {
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final formatDate = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

  final buffer = StringBuffer();
  buffer.writeln("=== LAPORAN TRANSAKSI DOMPETGWEH ===");
  buffer.writeln("Slogan: Catat masuknya dikit, keluarnya banyak.");
  buffer.writeln("Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}");
  buffer.writeln("====================================\n");

  double totalIncome = 0;
  double totalExpense = 0;

  for (final tx in transactions) {
    final isIncome = tx.type == 'income';
    if (isIncome) {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
    }

    final typeLabel = isIncome ? '[MASUK]' : '[KELUAR]';
    final sign = isIncome ? '+' : '-';
    
    buffer.writeln("${formatDate.format(tx.date)} $typeLabel");
    buffer.writeln("Kategori: ${tx.category}");
    buffer.writeln("Catatan : ${tx.description}");
    buffer.writeln("Nominal : $sign ${formatCurrency.format(tx.amount)}");
    buffer.writeln("------------------------------------");
  }

  buffer.writeln("\n=== RINGKASAN ===");
  buffer.writeln("Total Pemasukan  : ${formatCurrency.format(totalIncome)}");
  buffer.writeln("Total Pengeluaran : ${formatCurrency.format(totalExpense)}");
  buffer.writeln("Selisih (Saldo)  : ${formatCurrency.format(totalIncome - totalExpense)}");

  Clipboard.setData(ClipboardData(text: buffer.toString()));
}
