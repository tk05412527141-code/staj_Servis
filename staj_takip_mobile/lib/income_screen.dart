import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  String _userCompanyName = '';
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  double _totalIncome = 0;
  Map<String, double> _categoryIncome = {};
  List<double> _weeklyIncome = [0, 0, 0, 0];

  final List<String> _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        _userCompanyName = query.docs.first.data()['companyName'] ?? '';
        await _fetchIncomeData();
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchIncomeData() async {
    if (_userCompanyName.isEmpty) return;

    try {
      final startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
      final endOfMonth = DateTime(
        _selectedYear,
        _selectedMonth + 1,
        0,
        23,
        59,
        59,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('service_records')
          .where('companyName', isEqualTo: _userCompanyName)
          .get();

      double total = 0;
      Map<String, double> categories = {};
      List<double> weekly = [0, 0, 0, 0];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final price = (data['price'] ?? 0).toDouble();
        if (createdAt != null &&
            createdAt.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            createdAt.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          total += price;

          final category = data['deviceType'] ?? 'Diğer';
          categories[category] = (categories[category] ?? 0) + price;

          // Hafta hesapla
          final dayOfMonth = createdAt.day;
          int weekIndex;
          if (dayOfMonth <= 7) {
            weekIndex = 0;
          } else if (dayOfMonth <= 14) {
            weekIndex = 1;
          } else if (dayOfMonth <= 21) {
            weekIndex = 2;
          } else {
            weekIndex = 3;
          }
          weekly[weekIndex] += price;
        } else if (createdAt == null && price > 0) {
          // Tarihsiz kayıtlar da dahil
          total += price;
          final category = data['deviceType'] ?? 'Diğer';
          categories[category] = (categories[category] ?? 0) + price;
        }
      }

      if (mounted) {
        setState(() {
          _totalIncome = total;
          _categoryIncome = categories;
          _weeklyIncome = weekly;
        });
      }
    } catch (e) {
      debugPrint('Gelir verisi hatası: $e');
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _isLoading = true;
    });
    _fetchIncomeData().then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Gelirler'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ay seçici
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                          color: AppTheme.primaryBlue,
                        ),
                        Text(
                          '${_months[_selectedMonth - 1]} $_selectedYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toplam kazanç
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.dashboardGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Toplam Kazanç',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₺ ${_totalIncome.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Haftalık grafik
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Haftalık Dağılım',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  _weeklyIncome.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) *
                                      1.2 +
                                  100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '₺${rod.toY.toStringAsFixed(0)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const titles = [
                                        'Hafta 1',
                                        'Hafta 2',
                                        'Hafta 3',
                                        'Hafta 4',
                                      ];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          titles[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textGrey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(4, (index) {
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _weeklyIncome[index],
                                      color: AppTheme.primaryBlue,
                                      width: 24,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                      backDrawRodData:
                                          BackgroundBarChartRodData(
                                            show: true,
                                            toY:
                                                _weeklyIncome.reduce(
                                                      (a, b) => a > b ? a : b,
                                                    ) *
                                                    1.2 +
                                                100,
                                            color: AppTheme.lightBlue
                                                .withValues(alpha: 0.3),
                                          ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kategori dağılımı
                  const Text(
                    'Kategori Bazlı Gelirler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_categoryIncome.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Bu ay için gelir verisi yok.',
                          style: TextStyle(color: AppTheme.textGrey),
                        ),
                      ),
                    )
                  else
                    ...(_categoryIncome.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((entry) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    AppTheme.categoryIcon(entry.key),
                                    color: AppTheme.primaryBlue,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₺ ${entry.value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                ],
              ),
            ),
    );
  }
}
