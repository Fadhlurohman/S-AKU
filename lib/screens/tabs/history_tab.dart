import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../utils/report_printer.dart' as printer;
import '../../utils/formatters.dart';

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

  // Edit transaction dialog
  Future<void> _showEditTransactionDialog(TransactionProvider provider, Transaction tx) async {
    final formKey = GlobalKey<FormState>();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    String editType = tx.type;
    String editCategory = tx.category;
    final descCtrl = TextEditingController(text: tx.description);
    final amountCtrl = TextEditingController(
      text: currencyFormat.format(tx.amount).trim(),
    );
    DateTime editDate = tx.date;

    // Build category list based on type
    List<String> getCategories(String type) {
      return type == 'income'
          ? TransactionProvider.incomeCategories
          : TransactionProvider.expenseCategories;
    }

    // Make sure category is valid for the current type
    if (!getCategories(editType).contains(editCategory)) {
      editCategory = getCategories(editType).first;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            const accentColor = Color(0xFF10B981);
            final categories = getCategories(editType);

            return AlertDialog(
              title: const Text('Edit Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Type toggle
                        ToggleButtons(
                          isSelected: [editType == 'income', editType == 'expense'],
                          onPressed: (i) {
                            setStateDialog(() {
                              editType = i == 0 ? 'income' : 'expense';
                              // Reset category if not valid for new type
                              final cats = getCategories(editType);
                              if (!cats.contains(editCategory)) {
                                editCategory = cats.first;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: editType == 'income' ? accentColor : const Color(0xFFF43F5E),
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Pemasukan')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Pengeluaran')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: editCategory,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setStateDialog(() => editCategory = val ?? editCategory),
                          validator: (val) => val == null || val.isEmpty ? 'Pilih kategori' : null,
                        ),
                        const SizedBox(height: 12),
                        // Description
                        TextFormField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Masukkan deskripsi' : null,
                        ),
                        const SizedBox(height: 12),
                        // Amount
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            ThousandsSeparatorInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nominal (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Masukkan nominal';
                            final cleaned = val.replaceAll('.', '').replaceAll(',', '');
                            if (double.tryParse(cleaned) == null) return 'Nominal tidak valid';
                            if ((double.tryParse(cleaned) ?? 0) <= 0) return 'Nominal harus > 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Date picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: isDark
                                        ? const ColorScheme.dark(primary: Color(0xFF10B981), onPrimary: Colors.white)
                                        : const ColorScheme.light(primary: Color(0xFF10B981), onPrimary: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setStateDialog(() => editDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM yyyy', 'id_ID').format(editDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final cleanedAmount = amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
                    final updatedTx = Transaction(
                      id: tx.id,
                      type: editType,
                      category: editCategory,
                      description: descCtrl.text.trim(),
                      amount: double.parse(cleanedAmount),
                      date: editDate,
                    );
                    Navigator.of(context).pop();
                    // Confirmation before saving
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Konfirmasi Edit'),
                        content: const Text('Simpan perubahan transaksi ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await provider.updateTransaction(updatedTx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaksi berhasil diperbarui.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lanjut'),
                ),
              ],
            );
          },
        );
      },
    );

    descCtrl.dispose();
    amountCtrl.dispose();
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

    return SingleChildScrollView(
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
                  // Search Bar
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
                                setState(() { _searchQuery = ''; });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (val) { setState(() { _searchQuery = val; }); },
                  ),
                  const SizedBox(height: 12),
                  // Type & Category Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tipe',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'income', child: Text('Masuk', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'expense', child: Text('Keluar', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) { setState(() { _selectedType = val ?? 'all'; }); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('Semua', overflow: TextOverflow.ellipsis)),
                            ...allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (val) { setState(() { _selectedCategory = val ?? 'all'; }); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Month and Date Range Pickers
                  DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Bulan',
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
                    onChanged: (val) { setState(() { _selectedMonth = val ?? 'all'; }); },
                  ),
                  const SizedBox(height: 12),
                  _buildDateRangeSelector(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Transactions List Panel
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 480,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header of the list with counts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaksi (${filteredTransactions.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge when filters active
                              if (_searchQuery.isNotEmpty ||
                                  _selectedCategory != 'all' ||
                                  _selectedType != 'all' ||
                                  _selectedMonth != 'all' ||
                                  _startDate != null ||
                                  _endDate != null) ...[
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
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                icon: const Icon(Icons.print, size: 18, color: Color(0xFF10B981)),
                                onPressed: () {
                                  printer.printReport(filteredTransactions);
                                },
                                tooltip: 'Cetak Laporan',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: filteredTransactions.isEmpty
                          ? _buildEmptyState()
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
                    color: hasDate ? Theme.of(context).colorScheme.onSurface : Colors.grey,
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



  // Mobile Responsive ListView Layout
  Widget _buildMobileListView(TransactionProvider provider, List<Transaction> list) {
    final controller = ScrollController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scrollbarColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15);

    return RawScrollbar(
      controller: controller,
      thumbColor: scrollbarColor,
      radius: const Radius.circular(4),
      thickness: 4.0,
      child: ListView.separated(
        controller: controller,
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final tx = list[index];
          final isIncome = tx.type == 'income';
          final accentColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading icon
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accentColor.withOpacity(0.12),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: accentColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                // Middle: description, date + category + amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: description (full width)
                      Text(
                        tx.description,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Row 2: date + category chip + amount (next to category)
                      Row(
                        children: [
                          Text(
                            _dateFormat.format(tx.date),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tx.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "${isIncome ? '+' : '-'}${_formatAmount(tx.amount).replaceFirst('Rp', '').trim()}",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: accentColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Trailing: 3-dot menu only
                SizedBox(
                  height: 36,
                  width: 36,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    tooltip: 'Aksi',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditTransactionDialog(provider, tx);
                      } else if (value == 'delete') {
                        _deleteTransaction(provider, tx);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 10),
                            Text('Edit', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Color(0xFFF43F5E)),
                            SizedBox(width: 10),
                            Text('Hapus', style: TextStyle(fontSize: 13, color: Color(0xFFF43F5E))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


}
