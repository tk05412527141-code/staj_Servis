import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'widgets/status_badge.dart';
import 'service_detail_screen.dart';
import 'add_ticket_screen.dart';
import 'services/desktop_export_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _searchQuery = '';
  String _userCompanyName = '';
  bool _isLoading = true;
  String? _selectedFilter;

  final List<String> _filters = [
    'Tümü',
    'Bekliyor',
    'Atandı',
    'Yolda',
    'Tamamlandı',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCompany();
  }

  Future<void> _fetchCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        setState(() {
          _userCompanyName = query.docs.first.data()['companyName'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportServicesToCSV() async {
    if (_userCompanyName.isEmpty) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('service_records')
          .where('companyName', isEqualTo: _userCompanyName)
          .orderBy('createdAt', descending: true)
          .get();

      final headers = [
        'Ticket No',
        'Durum',
        'Müşteri Name',
        'Telefon',
        'Cihaz',
        'Detay',
        'Tarih',
        'Ücret',
        'Garanti',
      ];

      final rows = query.docs.map((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final dateStr = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : '';

        return [
          data['ticketNo'] ?? '',
          data['status'] ?? '',
          data['customerName'] ?? '',
          data['customerPhone'] ?? '',
          data['deviceType'] ?? '',
          data['deviceDetail'] ?? '',
          dateStr,
          data['price'] ?? 0,
          data['isWarranty'] == true ? 'Evet' : 'Hayır',
        ];
      }).toList();

      final result = await DesktopExportService.exportToCSV(
        'servis_kayitlari_${_userCompanyName}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        headers,
        rows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? 'Veriler başarıyla aktarıldı: $result'
                  : 'Dışa aktarma başarısız oldu',
            ),
            backgroundColor: result != null
                ? AppTheme.success
                : AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Servisler'),
        automaticallyImplyLeading: false,
        actions: [
          // Yenileme Butonu
          IconButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchCompany();
            },
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            tooltip: 'Yenile',
          ),
          // CSV Dışa Aktar Butonu
          IconButton(
            onPressed: _exportServicesToCSV,
            icon: const Icon(Icons.download, color: AppTheme.primaryBlue),
            tooltip: 'CSV Olarak İndir',
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddTicketScreen(companyName: _userCompanyName),
                ),
              );
            },
            icon: const Icon(Icons.add, color: AppTheme.primaryBlue),
            label: const Text(
              'Yeni',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Arama çubuğu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Ara...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textGrey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Filtreler
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected =
                          _selectedFilter == filter ||
                          (_selectedFilter == null && filter == 'Tümü');
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : null;
                            });
                          },
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textGrey,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Servis Listesi
                Expanded(child: _buildServicesList()),
              ],
            ),
    );
  }

  Widget _buildServicesList() {
    if (_userCompanyName.isEmpty) {
      return const Center(
        child: Text(
          'Şirket bilgisi bulunamadı.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('service_records')
          .where('companyName', isEqualTo: _userCompanyName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_outlined, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                const Text(
                  'Henüz servis kaydı yok',
                  style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        // Filtrele
        if (_selectedFilter != null && _selectedFilter != 'Tümü') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        // Arama
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final searchLower = _searchQuery.toLowerCase();
            return (data['ticketNo'] ?? '').toString().toLowerCase().contains(
                  searchLower,
                ) ||
                (data['customerName'] ?? '').toString().toLowerCase().contains(
                  searchLower,
                ) ||
                (data['deviceType'] ?? '').toString().toLowerCase().contains(
                  searchLower,
                ) ||
                (data['deviceDetail'] ?? '').toString().toLowerCase().contains(
                  searchLower,
                );
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Bekliyor';
            final ticketNo =
                data['ticketNo'] ?? '#${doc.id.substring(0, 5).toUpperCase()}';
            final deviceType = data['deviceType'] ?? '';
            final deviceDetail = data['deviceDetail'] ?? '';
            final customerName = data['customerName'] ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final isWarranty = data['isWarranty'] ?? false;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(
                      ticketId: doc.id,
                      companyName: _userCompanyName,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticketNo,
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$deviceType${deviceDetail.isNotEmpty ? ' • $deviceDetail' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Müşteri: $customerName',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          if (isWarranty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppTheme.success,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
