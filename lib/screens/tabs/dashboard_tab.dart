import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatters.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _budgetController = TextEditingController();
  bool _isObscured = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // Helper to format currency
  String _formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }

  // Dialog to edit initial balance
  void _showEditInitialBalanceDialog(BuildContext context, TransactionProvider provider) {
    final controller = TextEditingController(
      text: provider.initialBalance > 0
          ? NumberFormat.decimalPattern('id').format(provider.initialBalance)
          : ''
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Atur Saldo Awal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Masukkan nominal saldo awal Anda:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                inputFormatters: [
                  ThousandsSeparatorInputFormatter(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.replaceAll('.', '');
                final amount = double.tryParse(text) ?? 0.0;
                provider.setInitialBalance(amount);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to confirm reset balance
  void _showResetBalanceConfirmDialog(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Saldo & Transaksi'),
          content: const Text(
            'Apakah Anda yakin ingin mereset saldo awal menjadi Rp 0 dan menghapus semua riwayat transaksi? Tindakan ini tidak dapat dibatalkan.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                provider.resetBalance();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saldo awal dan semua transaksi berhasil di-reset.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  // Dialog to confirm reset budget limit
  void _showResetBudgetConfirmDialog(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Batas Anggaran'),
          content: const Text('Apakah Anda yakin ingin mereset batas anggaran bulanan menjadi Rp 0?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                provider.resetBudgetLimit();
                _budgetController.clear();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Batas anggaran bulanan berhasil di-reset.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final transactions = provider.transactions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 1. Calculate Summary Totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    double balance = provider.initialBalance + totalIncome - totalExpense;

    // 2. Calculate Current Month Expenses for Budget
    final now = DateTime.now();
    final currentYearMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    double currentMonthExpenses = 0.0;
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        final txYearMonth = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
        if (txYearMonth == currentYearMonth) {
          currentMonthExpenses += tx.amount;
        }
      }
    }

    final double budgetLimit = provider.budgetLimit;
    final double percent = budgetLimit > 0 ? (currentMonthExpenses / budgetLimit) * 100 : 0.0;
    final double progressPercent = (percent / 100).clamp(0.0, 1.0);

    // Sync input text controller with provider value
    if (budgetLimit == 0.0) {
      _budgetController.clear();
    } else if (_budgetController.text.isEmpty && budgetLimit > 0) {
      _budgetController.text = NumberFormat.decimalPattern('id').format(budgetLimit);
    }

    // Determine progress bar color
    Color budgetColor = const Color(0xFF10B981); // Green
    if (percent >= 100) {
      budgetColor = const Color(0xFFF43F5E); // Red
    } else if (percent >= 80) {
      budgetColor = const Color(0xFFF59E0B); // Orange/Amber
    }

    // Responsive checking
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Finansial',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? const Color(0xFFCBDCD0) : const Color(0xFF2D4236),
                ),
              ),
              IconButton(
                icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF10B981)),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                tooltip: _isObscured ? 'Tampilkan Nominal' : 'Sembunyikan Nominal',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row of Summary Cards (Balanced, Income, Expense)
          isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'TOTAL SALDO', 
                        balance, 
                        const Color(0xFF10B981), 
                        isDark,
                        subtitle: Row(
                          children: [
                            Text(
                              "Saldo Awal: ${_isObscured ? 'Rp ••••••' : _formatAmount(provider.initialBalance)}",
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                            ),
                            if (!provider.isInitialBalanceSet) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _showEditInitialBalanceDialog(context, provider),
                                child: const Icon(Icons.edit, size: 12, color: Color(0xFF10B981)),
                              ),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showResetBalanceConfirmDialog(context, provider),
                              child: const Icon(Icons.refresh, size: 12, color: Color(0xFFF43F5E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSummaryCard('PEMASUKAN', totalIncome, const Color(0xFF10B981), isDark, textPrefix: '+')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSummaryCard('PENGELUARAN', totalExpense, const Color(0xFFF43F5E), isDark, textPrefix: '-')),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(
                      'TOTAL SALDO', 
                      balance, 
                      const Color(0xFF10B981), 
                      isDark,
                      subtitle: Row(
                        children: [
                          Text(
                            "Saldo Awal: ${_isObscured ? 'Rp ••••••' : _formatAmount(provider.initialBalance)}",
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                          if (!provider.isInitialBalanceSet) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showEditInitialBalanceDialog(context, provider),
                              child: const Icon(Icons.edit, size: 12, color: Color(0xFF10B981)),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showResetBalanceConfirmDialog(context, provider),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 12, color: Color(0xFFF43F5E)),
                                SizedBox(width: 2),
                                Text(
                                  "Reset Saldo",
                                  style: TextStyle(fontSize: 10, color: Color(0xFFF43F5E), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard('PEMASUKAN', totalIncome, const Color(0xFF10B981), isDark, textPrefix: '+'),
                    const SizedBox(height: 12),
                    _buildSummaryCard('PENGELUARAN', totalExpense, const Color(0xFFF43F5E), isDark, textPrefix: '-'),
                  ],
                ),
          const SizedBox(height: 20),

          // Budget Limit Panel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monetization_on_outlined, size: 20, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            'Batas Anggaran Bulanan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      // Budget limit text input + reset button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 110,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F2015),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                                prefixText: 'Rp ',
                                prefixStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(),
                              ],
                              onSubmitted: (val) {
                                final cleanVal = val.replaceAll('.', '');
                                final limit = double.tryParse(cleanVal) ?? 0.0;
                                provider.setBudgetLimit(limit);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showResetBudgetConfirmDialog(context, provider),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0x33F43F5E) : const Color(0x1AF43F5E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.refresh, size: 16, color: Color(0xFFF43F5E)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Linear Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Progress Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terpakai: ${_isObscured ? "Rp ••••••" : _formatAmount(currentMonthExpenses)} / ${budgetLimit > 0 ? (_isObscured ? "Rp ••••••" : _formatAmount(budgetLimit)) : "Belum diatur"}',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBDCD0) : const Color(0xFF2D4236)),
                      ),
                      Text(
                        '${percent.round()}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: budgetColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Charts Section
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDonutChartCard(transactions, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBarChartCard(transactions, isDark)),
                  ],
                )
              : Column(
                  children: [
                    _buildDonutChartCard(transactions, isDark),
                    const SizedBox(height: 16),
                    _buildBarChartCard(transactions, isDark),
                  ],
                ),
        ],
      ),
    );
  }

  // Custom Summary Card Widget builder
  Widget _buildSummaryCard(String title, double amount, Color indicatorColor, bool isDark, {String textPrefix = '', Widget? subtitle}) {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: indicatorColor, width: 4.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isObscured
                  ? (textPrefix.isNotEmpty ? "$textPrefix ••••••" : "Rp ••••••")
                  : (textPrefix.isNotEmpty 
                      ? "$textPrefix ${_formatAmount(amount).replaceFirst('Rp', '').trim()}" 
                      : _formatAmount(amount)),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: title == 'TOTAL SALDO' 
                  ? (isDark ? Colors.white : const Color(0xFF0F2015))
                  : indicatorColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              subtitle,
            ],
          ],
        ),
      ),
    );
  }

  // Doughnut Chart (Distribution of expenses by category)
  Widget _buildDonutChartCard(List<Transaction> transactions, bool isDark) {
    // Process category data
    final Map<String, double> expensesData = {};
    for (var cat in TransactionProvider.expenseCategories) {
      expensesData[cat] = 0.0;
    }
    
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        expensesData[tx.category] = (expensesData[tx.category] ?? 0.0) + tx.amount;
      }
    }

    final categoriesWithValues = expensesData.keys.where((cat) => (expensesData[cat] ?? 0.0) > 0.0).toList();
    
    // Preset vibrant chart colors
    final List<Color> colors = [
      const Color(0xFFF43F5E), // rose red
      const Color(0xFF3B82F6), // blue
      const Color(0xFF10B981), // emerald green
      const Color(0xFFEAB308), // yellow
      const Color(0xFFA855F7), // purple
      const Color(0xFF06B6D4), // cyan
      const Color(0xFFF97316), // orange
    ];

    List<PieChartSectionData> sections = [];
    if (categoriesWithValues.isEmpty) {
      sections = [
        PieChartSectionData(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
          value: 1,
          title: 'Belum ada pengeluaran',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ];
    } else {
      sections = List.generate(categoriesWithValues.length, (index) {
        final cat = categoriesWithValues[index];
        final val = expensesData[cat] ?? 0.0;
        final color = colors[index % colors.length];
        return PieChartSectionData(
          color: color,
          value: val,
          radius: 35,
          showTitle: false, // Don't show text inside slices to stay clean
        );
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribusi Pengeluaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legends
            if (categoriesWithValues.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: List.generate(categoriesWithValues.length, (index) {
                  final cat = categoriesWithValues[index];
                  final color = colors[index % colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cat,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  // Bar Chart (Monthly income vs monthly expense comparison for the last 6 months)
  Widget _buildBarChartCard(List<Transaction> transactions, bool isDark) {
    // Process monthly data
    final Map<String, Map<String, double>> monthlyMap = {};
    for (var tx in transactions) {
      final m = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      if (!monthlyMap.containsKey(m)) {
        monthlyMap[m] = {'income': 0.0, 'expense': 0.0};
      }
      if (tx.type == 'income') {
        monthlyMap[m]!['income'] = (monthlyMap[m]!['income'] ?? 0.0) + tx.amount;
      } else {
        monthlyMap[m]!['expense'] = (monthlyMap[m]!['expense'] ?? 0.0) + tx.amount;
      }
    }

    final sortedMonths = monthlyMap.keys.toList()..sort();
    final displayMonths = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    final List<String> monthShorts = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"];
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < displayMonths.length; i++) {
      final m = displayMonths[i];
      final incomeVal = monthlyMap[m]!['income'] ?? 0.0;
      final expenseVal = monthlyMap[m]!['expense'] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: incomeVal,
              color: const Color(0xFF10B981), // Income green
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: expenseVal,
              color: const Color(0xFFF43F5E), // Expense red
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tren Bulanan (Masuk vs Keluar)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: barGroups.isEmpty
                  ? const Center(child: Text('Belum ada data bulanan', style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < displayMonths.length) {
                                  final m = displayMonths[idx];
                                  final parts = m.split('-');
                                  final mIdx = int.parse(parts[1]) - 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      "${monthShorts[mIdx]} '${parts[0].substring(2)}",
                                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Legends
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, color: const Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    const Text('Pemasukan', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(width: 8, height: 8, color: const Color(0xFFF43F5E)),
                    const SizedBox(width: 4),
                    const Text('Pengeluaran', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
