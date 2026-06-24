// Registrasi Service Worker untuk PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    // Reset service worker jika ada parameter reset=1 di URL
    if (window.location.search.includes('reset=1')) {
      navigator.serviceWorker.getRegistrations().then(registrations => {
        const unregisterPromises = registrations.map(r => r.unregister());
        caches.keys().then(names => {
          const deletePromises = names.map(name => caches.delete(name));
          Promise.all([...unregisterPromises, ...deletePromises]).then(() => {
            console.log('Service worker & cache dibersihkan!');
            window.location.href = window.location.pathname; // Reload tanpa query param
          }).catch(err => {
            console.error('Error saat mereset service worker/cache:', err);
            window.location.href = window.location.pathname;
          });
        });
      });
      return;
    }

    navigator.serviceWorker.register('./sw.js')
      .then(reg => console.log('Service Worker terdaftar!', reg.scope))
      .catch(err => console.log('Gagal mendaftarkan Service Worker:', err));
  });
}

// Konfigurasi Kategori Utama & Umum
const CATEGORIES = {
  income: ['Gaji', 'Investasi', 'Kado', 'Lain-lain'],
  expense: ['Makanan & Minuman', 'Transportasi', 'Hiburan', 'Tagihan', 'Belanja', 'Kesehatan', 'Lain-lain']
};

// Data Dummy Awal jika LocalStorage Kosong
const DUMMY_TRANSACTIONS = [
  { id: 1, type: 'income', category: 'Gaji', amount: 5000000, date: getOffsetDate(0), description: 'Gaji Bulanan Utama' },
  { id: 2, type: 'expense', category: 'Makanan & Minuman', amount: 45000, date: getOffsetDate(0), description: 'Makan Siang' },
  { id: 3, type: 'expense', category: 'Transportasi', amount: 150000, date: getOffsetDate(-1), description: 'Beli Bensin Mobil' },
  { id: 4, type: 'expense', category: 'Tagihan', amount: 200000, date: getOffsetDate(-2), description: 'Internet & Netflix' },
  { id: 5, type: 'income', category: 'Investasi', amount: 750000, date: getOffsetDate(-3), description: 'Dividen Reksa Dana' }
];

// Helper untuk membuat tanggal dummy relatif
function getOffsetDate(daysOffset) {
  const date = new Date();
  date.setDate(date.getDate() + daysOffset);
  return date.toISOString().split('T')[0];
}

// State Aplikasi
let transactions = [];
let budgetLimit = 0;

let donutChartInstance = null;
let barChartInstance = null;
let deferredPrompt = null;

// DOM Elements - Finansial & Tabel
const balanceEl = document.getElementById('total-balance');
const incomeEl = document.getElementById('total-income');
const expenseEl = document.getElementById('total-expense');
const transactionListEl = document.getElementById('transaction-list');
const transactionForm = document.getElementById('transaction-form');
const categorySelect = document.getElementById('category');
const filterCategorySelect = document.getElementById('filter-category');
const filterMonthSelect = document.getElementById('filter-month');
const installBtn = document.getElementById('install-btn');
const themeToggleBtn = document.getElementById('theme-toggle');

// DOM Elements - Tab Navigasi
const tabButtons = document.querySelectorAll('.nav-tab, .mobile-nav-tab');
const tabViews = document.querySelectorAll('.tab-view');

// DOM Elements - Limit Anggaran
const budgetLimitInput = document.getElementById('budget-limit-input');
const budgetProgressFill = document.getElementById('budget-progress-fill');
const budgetSpendingText = document.getElementById('budget-spending-text');
const budgetPercentText = document.getElementById('budget-percent-text');

// DOM Elements - Cari & Filter Tanggal
const searchInput = document.getElementById('search-input');
const startDateInput = document.getElementById('start-date');
const endDateInput = document.getElementById('end-date');
const btnClearDate = document.getElementById('btn-clear-date');

// DOM Elements - Ekspor & Impor (Tabel Riwayat)
const btnExportJson = document.getElementById('btn-export-json');
const btnExportCsv = document.getElementById('btn-export-csv');
const importFile = document.getElementById('import-file');

// Event Listeners
document.addEventListener('DOMContentLoaded', init);
transactionForm.addEventListener('submit', handleAddTransaction);
themeToggleBtn.addEventListener('click', toggleTheme);

// Event Listeners - Tab Switching
tabButtons.forEach(button => {
  button.addEventListener('click', () => {
    const target = button.dataset.target;
    switchTab(target);
  });
});

// Event Listeners - Anggaran
budgetLimitInput.addEventListener('change', handleBudgetLimitChange);
budgetLimitInput.addEventListener('keyup', (e) => {
  if (e.key === 'Enter') handleBudgetLimitChange();
});

// Event Listeners - Pencarian & Filter
searchInput.addEventListener('input', filterAndRender);
startDateInput.addEventListener('change', filterAndRender);
endDateInput.addEventListener('change', filterAndRender);
btnClearDate.addEventListener('click', () => {
  startDateInput.value = '';
  endDateInput.value = '';
  filterAndRender();
});

// Event Listeners - Ekspor & Impor
btnExportJson.addEventListener('click', exportBackupJson);
btnExportCsv.addEventListener('click', exportTransactionsCsv);
importFile.addEventListener('change', importBackupJson);

// Event Listeners - PWA Instalasi
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  if (installBtn) {
    installBtn.style.display = 'block';
  }
});

if (installBtn) {
  installBtn.addEventListener('click', async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    console.log(`User response to install prompt: ${outcome}`);
    deferredPrompt = null;
    installBtn.style.display = 'none';
  });
}

window.addEventListener('appinstalled', () => {
  console.log('DompetGweh berhasil diinstal!');
  if (installBtn) {
    installBtn.style.display = 'none';
  }
});

// Fungsi Inisialisasi Utama
function init() {
  // 1. Memuat Preferensi Tema
  const currentTheme = localStorage.getItem('theme') || 'dark';
  if (currentTheme === 'light') {
    document.body.classList.add('light-theme');
  }

  // 2. Memuat Data dari Storage
  loadStateFromStorage();

  // 3. Mengatur Tampilan Awal Form
  updateCategoryDropdown('expense', categorySelect);
  
  // 4. Mengatur Tipe transaksi di form
  initFormTypeSelector();

  // 5. Render Halaman
  populateFilterOptions();
  filterAndRender();
}

// Inisialisasi Tipe Selector Form
function initFormTypeSelector() {
  const typeSelector = document.getElementById('desktop-type-selector');
  if (!typeSelector) return;
  const typeButtons = typeSelector.querySelectorAll('.type-btn');

  typeButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      typeButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const type = btn.dataset.type;
      typeSelector.dataset.selectedType = type;
      updateCategoryDropdown(type, categorySelect);
    });
  });
}

// Memuat data dari LocalStorage
function loadStateFromStorage() {
  // Transaksi
  const storedTransactions = localStorage.getItem('transactions');
  if (storedTransactions) {
    transactions = JSON.parse(storedTransactions);
  } else {
    transactions = [...DUMMY_TRANSACTIONS];
    saveTransactions();
  }

  // Batas Anggaran
  const storedBudget = localStorage.getItem('budget_limit');
  if (storedBudget) {
    budgetLimit = parseFloat(storedBudget) || 0;
  } else {
    budgetLimit = 0;
  }
  
  // Update nilai input anggaran di UI
  budgetLimitInput.value = budgetLimit > 0 ? budgetLimit : '';
}

// Menyimpan transaksi
function saveTransactions() {
  localStorage.setItem('transactions', JSON.stringify(transactions));
}

// Memperbarui limit anggaran di Storage
function handleBudgetLimitChange() {
  const val = parseFloat(budgetLimitInput.value);
  budgetLimit = (!isNaN(val) && val >= 0) ? val : 0;
  localStorage.setItem('budget_limit', budgetLimit);
  filterAndRender();
}

// Fungsi untuk berpindah tab
function switchTab(targetTabId) {
  tabButtons.forEach(btn => {
    if (btn.dataset.target === targetTabId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  tabViews.forEach(view => {
    if (view.id === targetTabId) {
      view.classList.add('active');
    } else {
      view.classList.remove('active');
    }
  });

  if (targetTabId === 'view-dashboard') {
    setTimeout(() => {
      if (donutChartInstance) donutChartInstance.resize();
      if (barChartInstance) barChartInstance.resize();
    }, 50);
  }
}

// Fungsi untuk mengganti tema (Light / Dark)
function toggleTheme() {
  document.body.classList.toggle('light-theme');
  const theme = document.body.classList.contains('light-theme') ? 'light' : 'dark';
  localStorage.setItem('theme', theme);
  filterAndRender();
}

// Helper Format Rupiah
function formatRupiah(amount) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(amount);
}

// Memperbarui dropdown kategori berdasarkan tipe transaksi
function updateCategoryDropdown(type, selectElement) {
  selectElement.innerHTML = '';
  CATEGORIES[type].forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    selectElement.appendChild(opt);
  });
}

// Menambahkan Transaksi Baru
function handleAddTransaction(e) {
  e.preventDefault();
  
  const typeSelector = document.getElementById('desktop-type-selector');
  const type = typeSelector.dataset.selectedType || 'expense';
  
  const amountInput = transactionForm.querySelector('[name="amount"]');
  const categoryInput = transactionForm.querySelector('[name="category"]');
  const dateInput = transactionForm.querySelector('[name="date"]');
  const descInput = transactionForm.querySelector('[name="description"]');
  
  const amount = parseFloat(amountInput.value);
  const category = categoryInput.value;
  const date = dateInput.value;
  const description = descInput.value.trim();
  
  if (isNaN(amount) || amount <= 0 || !category || !date) {
    alert('Harap isi nominal, kategori, dan tanggal dengan benar!');
    return;
  }
  
  const newTransaction = {
    id: Date.now(),
    type,
    category,
    amount,
    date,
    description: description || category
  };
  
  transactions.push(newTransaction);
  saveTransactions();
  
  // Refresh UI
  populateFilterOptions();
  filterAndRender();
  
  // Reset Form
  transactionForm.reset();
  const typeButtons = typeSelector.querySelectorAll('.type-btn');
  typeButtons.forEach(b => b.classList.remove('active'));
  typeSelector.querySelector('[data-type="expense"]').classList.add('active');
  typeSelector.dataset.selectedType = 'expense';
  updateCategoryDropdown('expense', categorySelect);
  
  // Set default tanggal form ke hari ini setelah reset
  dateInput.value = new Date().toISOString().split('T')[0];
  
  // Pindahkan tab secara otomatis kembali ke Dashboard untuk melihat grafik & progress bar
  switchTab('view-dashboard');
}

// Menghapus Transaksi
function deleteTransaction(id) {
  if (confirm('Apakah Anda yakin ingin menghapus transaksi ini?')) {
    transactions = transactions.filter(t => t.id !== id);
    saveTransactions();
    populateFilterOptions();
    filterAndRender();
  }
}

// Mengisi Pilihan Filter Kategori & Bulan
function populateFilterOptions() {
  const currentCategory = filterCategorySelect.value;
  const currentMonth = filterMonthSelect.value;
  
  // Reset Filter Kategori
  filterCategorySelect.innerHTML = '<option value="all">Semua Kategori</option>';
  const allCats = new Set([...CATEGORIES.income, ...CATEGORIES.expense]);
  allCats.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    filterCategorySelect.appendChild(opt);
  });
  
  // Reset Filter Bulan
  filterMonthSelect.innerHTML = '<option value="all">Semua Bulan</option>';
  const months = new Set();
  transactions.forEach(t => {
    if (t.date) {
      months.add(t.date.substring(0, 7)); // format YYYY-MM
    }
  });
  
  const sortedMonths = Array.from(months).sort().reverse();
  sortedMonths.forEach(m => {
    const opt = document.createElement('option');
    opt.value = m;
    const [year, month] = m.split('-');
    const monthNames = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    opt.textContent = `${monthNames[parseInt(month) - 1]} ${year}`;
    filterMonthSelect.appendChild(opt);
  });
  
  if (Array.from(filterCategorySelect.options).some(o => o.value === currentCategory)) {
    filterCategorySelect.value = currentCategory;
  }
  if (Array.from(filterMonthSelect.options).some(o => o.value === currentMonth)) {
    filterMonthSelect.value = currentMonth;
  }
}

// Filter transaksi dan update ke UI + Chart + Progress Bar Anggaran
function filterAndRender() {
  const categoryFilter = filterCategorySelect.value;
  const monthFilter = filterMonthSelect.value;
  
  // Pencarian kata kunci & filter tanggal
  const keyword = searchInput.value.trim().toLowerCase();
  const startDateVal = startDateInput.value;
  const endDateVal = endDateInput.value;
  
  // 1. Hitung total finansial secara keseluruhan (untuk balance total)
  let totalIncome = 0;
  let totalExpense = 0;
  
  transactions.forEach(t => {
    if (t.type === 'income') totalIncome += t.amount;
    else totalExpense += t.amount;
  });
  
  balanceEl.textContent = formatRupiah(totalIncome - totalExpense);
  incomeEl.textContent = formatRupiah(totalIncome);
  expenseEl.textContent = formatRupiah(totalExpense);
  
  // 2. Hitung Pengeluaran Bulan Ini untuk Limit Anggaran Bulanan
  calculateAndRenderBudget(totalExpense);

  // 3. Filter data transaksi untuk tabel riwayat
  const filtered = transactions.filter(t => {
    const matchesCategory = categoryFilter === 'all' || t.category === categoryFilter;
    const matchesMonth = monthFilter === 'all' || (t.date && t.date.substring(0, 7) === monthFilter);
    
    // Filter pencarian
    const matchesKeyword = !keyword || 
      t.description.toLowerCase().includes(keyword) || 
      t.category.toLowerCase().includes(keyword);
      
    // Filter rentang tanggal
    const matchesStartDate = !startDateVal || t.date >= startDateVal;
    const matchesEndDate = !endDateVal || t.date <= endDateVal;
    
    return matchesCategory && matchesMonth && matchesKeyword && matchesStartDate && matchesEndDate;
  });
  
  filtered.sort((a, b) => new Date(b.date) - new Date(a.date));
  renderTable(filtered);
  renderCharts();
}

// Perhitungan Limit Anggaran Bulanan (Pengeluaran Bulan Berjalan)
function calculateAndRenderBudget() {
  const currentYearMonth = new Date().toISOString().substring(0, 7); // YYYY-MM
  
  const currentMonthExpenses = transactions.filter(t => 
    t.type === 'expense' && t.date && t.date.substring(0, 7) === currentYearMonth
  );
  
  const totalSpentThisMonth = currentMonthExpenses.reduce((sum, t) => sum + t.amount, 0);
  const percent = budgetLimit > 0 ? Math.min((totalSpentThisMonth / budgetLimit) * 100, 100) : 0;
  
  budgetProgressFill.style.width = percent + '%';
  budgetProgressFill.classList.remove('warning', 'danger');
  if (percent >= 100) {
    budgetProgressFill.classList.add('danger');
  } else if (percent >= 80) {
    budgetProgressFill.classList.add('warning');
  }
  
  budgetSpendingText.textContent = `Terpakai: ${formatRupiah(totalSpentThisMonth)} / ${budgetLimit > 0 ? formatRupiah(budgetLimit) : 'Belum diatur'}`;
  budgetPercentText.textContent = `${Math.round(percent)}%`;
}

// Merender tabel transaksi
function renderTable(data) {
  transactionListEl.innerHTML = '';
  
  if (data.length === 0) {
    transactionListEl.innerHTML = `
      <tr>
        <td colspan="5">
          <div class="empty-state">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
              <line x1="16" y1="2" x2="16" y2="6"/>
              <line x1="8" y1="2" x2="8" y2="6"/>
              <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
            <p>Tidak ada transaksi yang ditemukan.</p>
          </div>
        </td>
      </tr>
    `;
    return;
  }
  
  data.forEach(t => {
    const tr = document.createElement('tr');
    const d = new Date(t.date);
    const dateFormatted = d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
    const amountClass = t.type === 'income' ? 'income' : 'expense';
    const amountPrefix = t.type === 'income' ? '+' : '-';
    
    tr.innerHTML = `
      <td>${dateFormatted}</td>
      <td><span class="badge badge-category">${t.category}</span></td>
      <td>${t.description}</td>
      <td class="td-amount ${amountClass}">${amountPrefix} ${formatRupiah(t.amount).replace('Rp', '').trim()}</td>
      <td style="text-align: right; width: 50px;">
        <button class="btn-delete" onclick="deleteTransaction(${t.id})" title="Hapus Transaksi">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"/>
            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
            <line x1="10" y1="11" x2="10" y2="17"/>
            <line x1="14" y1="11" x2="14" y2="17"/>
          </svg>
        </button>
      </td>
    `;
    
    transactionListEl.appendChild(tr);
  });
}

// Cadangan Data - Ekspor JSON Backup
function exportBackupJson() {
  const backup = {
    version: '1.0',
    transactions,
    budgetLimit
  };
  
  const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  
  const a = document.createElement('a');
  a.href = url;
  a.download = `dompetgweh_backup_${getOffsetDate(0)}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// Cadangan Data - Impor JSON Backup
function importBackupJson(e) {
  const file = e.target.files[0];
  if (!file) return;
  
  const reader = new FileReader();
  reader.onload = function(evt) {
    try {
      const data = JSON.parse(evt.target.result);
      
      if (!data.transactions || !Array.isArray(data.transactions)) {
        throw new Error('Berkas cadangan tidak valid.');
      }
      
      if (confirm('Impor data akan menimpa seluruh data transaksi Anda saat ini. Lanjutkan?')) {
        transactions = data.transactions;
        budgetLimit = data.budgetLimit || 0;
        
        saveTransactions();
        localStorage.setItem('budget_limit', budgetLimit);
        
        alert('Data berhasil diimpor!');
        loadStateFromStorage();
        updateCategoryDropdown('expense', categorySelect);
        populateFilterOptions();
        filterAndRender();
        switchTab('view-dashboard');
      }
    } catch(err) {
      alert(`Gagal memuat berkas cadangan: ${err.message}`);
    }
    importFile.value = '';
  };
  reader.readAsText(file);
}

// Cadangan Data - Ekspor Tabel ke CSV (Excel)
function exportTransactionsCsv() {
  if (transactions.length === 0) {
    alert('Tidak ada transaksi untuk diekspor!');
    return;
  }
  
  let csvContent = '\uFEFF';
  csvContent += 'ID,Tanggal,Tipe,Kategori,Nominal (IDR),Catatan\n';
  
  transactions.forEach(t => {
    const description = `"${t.description.replace(/"/g, '""')}"`;
    const typeLabel = t.type === 'income' ? 'Pemasukan' : 'Pengeluaran';
    csvContent += `${t.id},${t.date},${typeLabel},${t.category},${t.amount},${description}\n`;
  });
  
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  
  const a = document.createElement('a');
  a.href = url;
  a.download = `dompetgweh_transaksi_${getOffsetDate(0)}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// Membuat & Memperbarui Grafik
function renderCharts() {
  const monthFilter = filterMonthSelect.value;
  const chartDataList = monthFilter === 'all' 
    ? transactions 
    : transactions.filter(t => t.date && t.date.substring(0, 7) === monthFilter);

  // Konfigurasi Warna berdasarkan Tema Aktif (Light / Dark)
  const isLightTheme = document.body.classList.contains('light-theme');
  const textColor = isLightTheme ? '#334155' : '#cbd5e1';
  const gridColor = isLightTheme ? 'rgba(15, 23, 42, 0.08)' : 'rgba(255, 255, 255, 0.08)';
  const tickColor = isLightTheme ? '#475569' : '#94a3b8';
  const donutBorderColor = isLightTheme ? '#ffffff' : '#111827';
  
  const tooltipBg = isLightTheme ? '#ffffff' : '#1f2937';
  const tooltipText = isLightTheme ? '#0f172a' : '#f3f4f6';
  const tooltipBody = isLightTheme ? '#475569' : '#cbd5e1';
  const tooltipBorderColor = isLightTheme ? 'rgba(15, 23, 42, 0.12)' : 'rgba(255, 255, 255, 0.12)';

  // --- 1. PROSES DATA GRAFIK DONUT (PENGELUARAN SAJA) ---
  const expenseData = {};
  CATEGORIES.expense.forEach(c => expenseData[c] = 0);
  
  chartDataList.forEach(t => {
    if (t.type === 'expense') {
      expenseData[t.category] = (expenseData[t.category] || 0) + t.amount;
    }
  });
  
  const donutLabels = Object.keys(expenseData).filter(c => expenseData[c] > 0);
  const donutValues = donutLabels.map(c => expenseData[c]);
  
  const chartColors = [
    '#f43f5e', // rose
    '#3b82f6', // blue
    '#10b981', // emerald
    '#eab308', // yellow
    '#a855f7', // purple
    '#06b6d4', // cyan
    '#f97316'  // orange
  ];

  const donutCtx = document.getElementById('donutChart').getContext('2d');
  
  if (donutChartInstance) {
    donutChartInstance.destroy();
  }
  
  if (donutValues.length === 0) {
    donutChartInstance = new Chart(donutCtx, {
      type: 'doughnut',
      data: {
        labels: ['Tidak Ada Pengeluaran'],
        datasets: [{
          data: [1],
          backgroundColor: [isLightTheme ? 'rgba(0, 0, 0, 0.04)' : 'rgba(255, 255, 255, 0.05)'],
          borderColor: [isLightTheme ? 'rgba(0, 0, 0, 0.06)' : 'rgba(255, 255, 255, 0.08)'],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: tickColor, font: { family: 'Inter' } } },
          tooltip: { enabled: false }
        }
      }
    });
  } else {
    donutChartInstance = new Chart(donutCtx, {
      type: 'doughnut',
      data: {
        labels: donutLabels,
        datasets: [{
          data: donutValues,
          backgroundColor: chartColors.slice(0, donutLabels.length),
          borderColor: donutBorderColor,
          borderWidth: 2,
          hoverOffset: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: textColor,
              font: { family: 'Inter', size: 11, weight: 500 },
              padding: 15,
              usePointStyle: true,
              pointStyle: 'circle'
            }
          },
          tooltip: {
            backgroundColor: tooltipBg,
            titleColor: tooltipText,
            bodyColor: tooltipBody,
            bodyFont: { family: 'Inter' },
            borderColor: tooltipBorderColor,
            borderWidth: 1,
            callbacks: {
              label: function(context) {
                return ` ${context.label}: ${formatRupiah(context.raw)}`;
              }
            }
          }
        },
        cutout: '70%'
      }
    });
  }

  // --- 2. PROSES DATA GRAFIK BATANG (TREN BULANAN PEMASUKAN VS PENGELUARAN) ---
  const monthlyData = {};
  
  transactions.forEach(t => {
    if (!t.date) return;
    const m = t.date.substring(0, 7);
    if (!monthlyData[m]) {
      monthlyData[m] = { income: 0, expense: 0 };
    }
    if (t.type === 'income') {
      monthlyData[m].income += t.amount;
    } else {
      monthlyData[m].expense += t.amount;
    }
  });
  
  const sortedMonths = Object.keys(monthlyData).sort();
  const displayMonths = sortedMonths.slice(-6);
  
  const barLabels = displayMonths.map(m => {
    const [year, month] = m.split('-');
    const monthShorts = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"];
    return `${monthShorts[parseInt(month) - 1]} ${year.substring(2)}`;
  });
  
  const barIncomeValues = displayMonths.map(m => monthlyData[m].income);
  const barExpenseValues = displayMonths.map(m => monthlyData[m].expense);
  
  const barCtx = document.getElementById('barChart').getContext('2d');
  
  if (barChartInstance) {
    barChartInstance.destroy();
  }
  
  barChartInstance = new Chart(barCtx, {
    type: 'bar',
    data: {
      labels: barLabels.length > 0 ? barLabels : ['Belum Ada Data'],
      datasets: [
        {
          label: 'Pemasukan',
          data: barIncomeValues.length > 0 ? barIncomeValues : [0],
          backgroundColor: '#10b981',
          borderRadius: 6,
          borderWidth: 0,
          maxBarThickness: 20
        },
        {
          label: 'Pengeluaran',
          data: barExpenseValues.length > 0 ? barExpenseValues : [0],
          backgroundColor: '#f43f5e',
          borderRadius: 6,
          borderWidth: 0,
          maxBarThickness: 20
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'bottom',
          labels: {
            color: textColor,
            font: { family: 'Inter', size: 11, weight: 500 },
            usePointStyle: true,
            pointStyle: 'circle'
          }
        },
        tooltip: {
          backgroundColor: tooltipBg,
          titleColor: tooltipText,
          bodyColor: tooltipBody,
          bodyFont: { family: 'Inter' },
          borderColor: tooltipBorderColor,
          borderWidth: 1,
          callbacks: {
            label: function(context) {
              return ` ${context.dataset.label}: ${formatRupiah(context.raw)}`;
            }
          }
        }
      },
      scales: {
        x: {
          grid: { display: false },
          ticks: { color: tickColor, font: { family: 'Inter', size: 10 } }
        },
        y: {
          grid: { color: gridColor },
          ticks: {
            color: tickColor,
            font: { family: 'Inter', size: 10 },
            callback: function(value) {
              if (value >= 1000000) return (value / 1000000) + 'jt';
              if (value >= 1000) return (value / 1000) + 'rb';
              return value;
            }
          }
        }
      }
    }
  });
}
