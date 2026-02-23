import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'customers_screen.dart';
import 'add_ticket_screen.dart';
import 'add_employee_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCompanyName = '';
  String _userRole = '';
  bool _isLoading = true;

  int _activeCount = 0;
  int _pendingCount = 0;
  int _completedCount = 0;
  double _totalIncome = 0;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final companyName = userData['companyName'] ?? '';

          setState(() {
            _userName =
                userData['name'] ?? user.email?.split('@')[0] ?? 'Kullanıcı';
            _userCompanyName = companyName;
            _userRole = userData['role'] ?? 'employee';
          });

          // İstatistikleri getir
          if (companyName.isNotEmpty) {
            _fetchStats(companyName);
          }
        }
      }
    } catch (e) {
      debugPrint('Veri çekme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStats(String companyName) async {
    try {
      final ticketsQuery = await FirebaseFirestore.instance
          .collection('service_records')
          .where('companyName', isEqualTo: companyName)
          .get();

      int active = 0, pending = 0, completed = 0;
      double income = 0;

      for (var doc in ticketsQuery.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'Bekliyor').toString().toLowerCase();
        if (status == 'tamamlandı' || status == 'tamamlandi') {
          completed++;
        } else if (status == 'bekliyor') {
          pending++;
        } else {
          active++;
        }
        income += (data['price'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _activeCount = active;
          _pendingCount = pending;
          _completedCount = completed;
          _totalIncome = income;
          _messageCount = pending; // Mesaj olarak bekleyen servisleri göster
        });
      }
    } catch (e) {
      debugPrint('İstatistik hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          // Gradient üst kısım
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Fade efekti
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.backgroundGrey.withValues(alpha: 0),
                    AppTheme.backgroundGrey,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst bar: Hoş Geldin
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'K',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş Geldin,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _fetchUserData();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 26,
                            color: Colors.white,
                          ),
                          tooltip: 'Yenile',
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 28,
                                color: Colors.white,
                              ),
                              if (_messageCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_messageCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dashboard kartı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _dashboardItem(
                                'Bugünkü\nServisler',
                                '${_activeCount + _pendingCount}',
                              ),
                              const SizedBox(width: 16),
                              _dashboardItem(
                                'Bekleyen\nServisler',
                                '$_pendingCount',
                              ),
                              const SizedBox(width: 16),
                              _dashboardItem(
                                'Ödeme',
                                '₺${_totalIncome.toStringAsFixed(0)}',
                              ),
                              const SizedBox(width: 16),
                              _dashboardItem('Mesajlar', '$_messageCount'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hızlı erişim butonları
                    Row(
                      children: [
                        _quickAccessButton(
                          icon: Icons.build,
                          label: 'Servisler',
                          color: AppTheme.primaryBlue,
                          onTap: () {
                            // Servisler tabına geç - parent'a bildir
                          },
                        ),
                        const SizedBox(width: 12),
                        _quickAccessButton(
                          icon: Icons.people,
                          label: 'Müşteriler',
                          color: AppTheme.danger,
                          badge:
                              '${_completedCount > 0 ? _completedCount : ''}',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomersScreen(
                                  companyName: _userCompanyName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _quickAccessButton(
                          icon: Icons.account_balance_wallet,
                          label: 'Gelirler',
                          color: AppTheme.success,
                          onTap: () {
                            // Gelirler tabına geç
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _quickAccessButton(
                          icon: Icons.group,
                          label: 'Çalışanlar',
                          color: AppTheme.accentTeal,
                          onTap: () {
                            if (_userRole == 'manager' ||
                                _userRole == 'owner' ||
                                _userRole == 'admin') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEmployeeScreen(
                                    managerCompanyName: _userCompanyName,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bu özellik sadece yöneticiler içindir.',
                                  ),
                                  backgroundColor: AppTheme.warning,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Container()),
                        const SizedBox(width: 12),
                        Expanded(child: Container()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Yeni Servis Ekle butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddTicketScreen(
                                companyName: _userCompanyName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Yeni Servis Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Son Servisler - mini liste
                    const Text(
                      'Son Servisler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _recentServicesStream(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  if (badge != null && badge.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentServicesStream() {
    if (_userCompanyName.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Henüz bir şirkete atanmadınız.\nLütfen yöneticinizle iletişime geçin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_records')
          .where('companyName', isEqualTo: _userCompanyName)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Henüz servis kaydı yok.',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Bekliyor';
            final statusColor = AppTheme.statusColor(status);

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
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['ticketNo'] ?? '#${doc.id.substring(0, 5)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        Text(
                          '${data['deviceType'] ?? ''} • ${data['customerName'] ?? data['serviceEmployee'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
