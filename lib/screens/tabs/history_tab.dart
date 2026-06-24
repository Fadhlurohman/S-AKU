import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/report_printer.dart' as printer;
import 'package:flutter/foundation.dart' show kIsWeb;

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedType = 'all'; // 'all', 'income', 'expense'
  String _selectedMonth = 'all'; // 'all' or 'YYYY-MM'
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Format currency
  String _formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }

  // Show Date Range Picker
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null ? initialDateRange : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Color(0xFF0D1B14),
                    onSurface: Color(0xFFCBDCD0),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Color(0xFFF2FAF6),
                    onSurface: Color(0xFF0F2015),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        // Set end date to end of day to include transactions on that date
        _endDate = DateTime(pickedRange.end.year, pickedRange.end.month, pickedRange.end.day, 23, 59, 59);
      });
    }
  }

  // Clear Date Filters
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }


  // Delete transaction confirm
  Future<void> _deleteTransaction(TransactionProvider provider, Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await provider.deleteTransaction(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    // Gather all categories for dropdown filter
    final allCategories = {
      ...TransactionProvider.incomeCategories,
      ...TransactionProvider.expenseCategories
    }.toList();

    // Gather unique months for month filter
    final uniqueMonths = provider.transactions.map((tx) {
      return "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
    }).toSet().toList()..sort((a, b) => b.compareTo(a));

    // Filter transaction list
    final filteredTransactions = provider.transactions.where((tx) {
      // 1. Search Query (description or category)
      final matchesSearch = _searchQuery.isEmpty ||
          tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Type Filter
      final matchesType = _selectedType == 'all' || tx.type == _selectedType;

      // 3. Category Filter
      final matchesCategory = _selectedCategory == 'all' || tx.category == _selectedCategory;

      // 4. Month Filter
      final txMonthStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      final matchesMonth = _selectedMonth == 'all' || txMonthStr == _selectedMonth;

      // 5. Date Range Filter
      final matchesStartDate = _startDate == null || tx.date.isAfter(_startDate!) || tx.date.isAtSameMomentAs(_startDate!);
      final matchesEndDate = _endDate == null || tx.date.isBefore(_endDate!) || tx.date.isAtSameMomentAs(_endDate!);

      return matchesSearch && matchesType && matchesCategory && matchesMonth && matchesStartDate && matchesEndDate;
    }).toList();

    // Sort by date descending
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Screen responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Pencarian',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar + Type Filter + Category Filter Row/Column
                  isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  labelText: 'Cari deskripsi / kategori...',
                                  hintText: 'Contoh: Makan siang',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  labelText: 'Tipe',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('Semua Tipe')),
                                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedType = val ?? 'all';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Kategori',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
                                  ...allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategory = val ?? 'all';
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Cari deskripsi / kategori...',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                              onChanged: (val) {
                                setState(() {
                                    _searchQuery = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    decoration: InputDecoration(
                                      labelText: 'Tipe',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('Semua')),
                                      DropdownMenuItem(value: 'income', child: Text('Masuk')),
                                      DropdownMenuItem(value: 'expense', child: Text('Keluar')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedType = val ?? 'all';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: 'Kategori',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: 'all', child: Text('Semua')),
                                      ...allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCategory = val ?? 'all';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  // Month and Date Range Pickers
                  isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                decoration: InputDecoration(
                                  labelText: 'Bulan (Tren)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text('Semua Bulan')),
                                  ...uniqueMonths.map((m) {
                                    final parts = m.split('-');
                                    final monthInt = int.parse(parts[1]);
                                    final yearStr = parts[0];
                                    final monthNames = [
                                      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
                                      "Juli", "Agustus", "September", "Okt", "November", "Desember"
                                    ];
                                    final label = "${monthNames[monthInt - 1]} $yearStr";
                                    return DropdownMenuItem(value: m, child: Text(label));
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedMonth = val ?? 'all';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date Range Picker button
                            Expanded(
                              child: _buildDateRangeSelector(context),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedMonth,
                              decoration: InputDecoration(
                                labelText: 'Bulan (Tren)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                              items: [
                                const DropdownMenuItem(value: 'all', child: Text('Semua Bulan')),
                                ...uniqueMonths.map((m) {
                                  final parts = m.split('-');
                                  final monthInt = int.parse(parts[1]);
                                  final yearStr = parts[0];
                                  final monthNames = [
                                    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
                                    "Juli", "Agustus", "September", "Oktober", "November", "Desember"
                                  ];
                                  final label = "${monthNames[monthInt - 1]} $yearStr";
                                  return DropdownMenuItem(value: m, child: Text(label));
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedMonth = val ?? 'all';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDateRangeSelector(context),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Transactions List Panel
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header of the list with counts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Transaksi (${filteredTransactions.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.print, size: 18, color: Color(0xFF10B981)),
                                onPressed: () {
                                  printer.printReport(filteredTransactions);
                                  if (!kIsWeb) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Laporan teks berhasil disalin ke clipboard!'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                },
                                tooltip: 'Cetak Laporan',
                              ),
                            ],
                          ),
                          // Optional badge for filters active
                          if (_searchQuery.isNotEmpty ||
                              _selectedCategory != 'all' ||
                              _selectedType != 'all' ||
                              _selectedMonth != 'all' ||
                              _startDate != null ||
                              _endDate != null)
                            ActionChip(
                              label: const Text('Reset Filter', style: TextStyle(fontSize: 11, color: Colors.white)),
                              backgroundColor: const Color(0xFFF43F5E),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'all';
                                  _selectedType = 'all';
                                  _selectedMonth = 'all';
                                  _startDate = null;
                                  _endDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredTransactions.isEmpty
                          ? _buildEmptyState()
                          : isDesktop
                              ? _buildDesktopTable(provider, filteredTransactions)
                              : _buildMobileListView(provider, filteredTransactions),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Date Range Selector button/row
  Widget _buildDateRangeSelector(BuildContext context) {
    final hasDate = _startDate != null && _endDate != null;
    final text = hasDate
        ? "${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}"
        : "Pilih Rentang Tanggal";

    return InkWell(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasDate ? Theme.of(context).colorScheme.onBackground : Colors.grey,
                    fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (hasDate)
              GestureDetector(
                onTap: () {
                  _clearDateFilter();
                },
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              )
            else
              const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada transaksi yang ditemukan.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba sesuaikan filter Anda.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Responsive Table Layout
  Widget _buildDesktopTable(TransactionProvider provider, List<Transaction> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: const BoxConstraints(minWidth: 700),
          child: DataTable(
            columnSpacing: 24.0,
            horizontalMargin: 16.0,
            columns: const [
              DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nominal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: list.map((tx) {
              final isIncome = tx.type == 'income';
              return DataRow(
                cells: [
                  DataCell(Text(_dateFormat.format(tx.date))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isIncome 
                            ? const Color(0xFF10B981).withOpacity(0.1) 
                            : const Color(0xFFF43F5E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isIncome 
                              ? const Color(0xFF10B981).withOpacity(0.2) 
                              : const Color(0xFFF43F5E).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tx.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(tx.description)),
                  DataCell(
                    Text(
                      "${isIncome ? '+' : '-'} ${_formatAmount(tx.amount).replaceFirst('Rp ', '').trim()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFF43F5E), size: 20),
                      onPressed: () => _deleteTransaction(provider, tx),
                      tooltip: 'Hapus Transaksi',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Mobile Responsive ListView Layout
  Widget _buildMobileListView(TransactionProvider provider, List<Transaction> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final tx = list[index];
        final isIncome = tx.type == 'income';
        
        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: const Color(0xFFF43F5E),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (dir) async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Hapus Transaksi'),
                  content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.description}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
            return confirm;
          },
          onDismissed: (dir) {
            provider.deleteTransaction(tx.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transaksi "${tx.description}" dihapus'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome 
                  ? const Color(0xFF10B981).withOpacity(0.1) 
                  : const Color(0xFFF43F5E).withOpacity(0.1),
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                size: 18,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    tx.description,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${isIncome ? '+' : '-'} ${_formatAmount(tx.amount).replaceFirst('Rp ', '').trim()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(tx.date),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isIncome 
                        ? const Color(0xFF10B981).withOpacity(0.08) 
                        : const Color(0xFFF43F5E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tx.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}
