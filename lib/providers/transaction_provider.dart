import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  double _budgetLimit = 0.0;
  double _initialBalance = 0.0;
  ThemeMode _themeMode = ThemeMode.dark;

  // Categories definition
  static const List<String> incomeCategories = ['Gaji', 'Lain-lain'];
  static const List<String> expenseCategories = [
    'Makanan/Minuman',
    'Hiburan',
    'Tagihan',
    'Belanja',
    'Lain-lain'
  ];

  List<Transaction> get transactions => _transactions;
  double get budgetLimit => _budgetLimit;
  double get initialBalance => _initialBalance;
  ThemeMode get themeMode => _themeMode;

  TransactionProvider() {
    loadState();
  }

  // Load state from SharedPreferences
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load budget limit
    _budgetLimit = prefs.getDouble('budget_limit') ?? 0.0;

    // Load initial balance
    _initialBalance = prefs.getDouble('initial_balance') ?? 0.0;

    // Load theme mode
    final themeStr = prefs.getString('theme_mode') ?? 'dark';
    _themeMode = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;

    // Load transactions
    final txListJson = prefs.getStringList('transactions');
    if (txListJson != null) {
      try {
        _transactions = txListJson.map((txStr) {
          final txMap = jsonDecode(txStr) as Map<String, dynamic>;
          return Transaction.fromJson(txMap);
        }).toList();
      } catch (e) {
        debugPrint("Error loading transactions: $e");
        _transactions = [];
      }
    } else {
      // Setup initial dummy data if storage is empty (same as vanilla app)
      _setupDummyData();
      await saveTransactions();
    }
    
    notifyListeners();
  }

  // Setup Dummy Data
  void _setupDummyData() {
    _transactions = [];
  }

  // Save transactions to SharedPreferences
  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final txListJson = _transactions.map((tx) => jsonEncode(tx.toJson())).toList();
    await prefs.setStringList('transactions', txListJson);
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction tx) async {
    _transactions.add(tx);
    await saveTransactions();
    notifyListeners();
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((tx) => tx.id == id);
    await saveTransactions();
    notifyListeners();
  }

  // Set monthly budget limit
  Future<void> setBudgetLimit(double limit) async {
    _budgetLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
    notifyListeners();
  }

  // Set initial balance
  Future<void> setInitialBalance(double balance) async {
    _initialBalance = balance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('initial_balance', balance);
    notifyListeners();
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  // Toggle theme mode
  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  // Export Backup JSON string
  String exportBackupJson() {
    final backupMap = {
      'version': '1.0',
      'budgetLimit': _budgetLimit,
      'initialBalance': _initialBalance,
      'transactions': _transactions.map((tx) => tx.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  // Import Backup JSON string
  Future<bool> importBackupJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (!data.containsKey('transactions')) return false;

      final rawList = data['transactions'] as List<dynamic>;
      final newTransactions = rawList.map((item) {
        return Transaction.fromJson(item as Map<String, dynamic>);
      }).toList();

      _transactions = newTransactions;
      _budgetLimit = (data['budgetLimit'] as num?)?.toDouble() ?? 0.0;
      _initialBalance = (data['initialBalance'] as num?)?.toDouble() ?? 0.0;

      await saveTransactions();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('budget_limit', _budgetLimit);
      await prefs.setDouble('initial_balance', _initialBalance);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error importing backup: $e");
      return false;
    }
  }

  // Export Transactions to CSV string
  String exportTransactionsCsv() {
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');
    buffer.write('ID,Tanggal,Tipe,Kategori,Nominal (IDR),Catatan\n');
    
    for (final t in _transactions) {
      final dateStr = t.date.toIso8601String().split('T')[0];
      final typeLabel = t.type == 'income' ? 'Pemasukan' : 'Pengeluaran';
      // Escape description quotes
      final descEscaped = '"${t.description.replaceAll('"', '""')}"';
      buffer.write('${t.id},$dateStr,$typeLabel,${t.category},${t.amount},$descEscaped\n');
    }
    
    return buffer.toString();
  }
}
