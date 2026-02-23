import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'widgets/status_badge.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String ticketId;
  final String companyName;

  const ServiceDetailScreen({
    super.key,
    required this.ticketId,
    required this.companyName,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map<String, dynamic>? _ticketData;
  bool _isLoading = true;

  final List<String> _statusOptions = [
    'Bekliyor',
    'Atandı',
    'Yolda',
    'Tamamlandı',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_records')
          .doc(widget.ticketId)
          .get();

      if (doc.exists) {
        setState(() {
          _ticketData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Ticket fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Mevcut status history'yi al
      List<dynamic> history =
          (_ticketData?['statusHistory'] as List<dynamic>?) ?? [];
      history.add({
        'status': newStatus,
        'time': timeStr,
        'timestamp': Timestamp.fromDate(now),
      });

      await FirebaseFirestore.instance
          .collection('service_records')
          .doc(widget.ticketId)
          .update({
            'status': newStatus,
            'updatedAt': Timestamp.fromDate(now),
            'statusHistory': history,
          });

      await _fetchTicket();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Durum "$newStatus" olarak güncellendi'),
            backgroundColor: AppTheme.success,
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

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_ticketData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Servis Detayı')),
        body: const Center(child: Text('Servis bulunamadı.')),
      );
    }

    final data = _ticketData!;
    final status = data['status'] ?? 'Bekliyor';
    final ticketNo = data['ticketNo'] ?? '#${widget.ticketId.substring(0, 5)}';
    final customerName = data['customerName'] ?? '';
    final customerPhone = data['customerPhone'] ?? '';
    final address = data['address'] ?? '';
    final deviceType = data['deviceType'] ?? '';
    final deviceDetail = data['deviceDetail'] ?? '';
    final description = data['description'] ?? '';
    final isWarranty = data['isWarranty'] ?? false;
    final price = (data['price'] ?? 0).toDouble();
    final statusHistory = (data['statusHistory'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Servis Detayı'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.danger),
                    SizedBox(width: 8),
                    Text('Sil'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket no + status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Müşteri bilgisi
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName.isNotEmpty
                                  ? customerName
                                  : 'İsimsiz Müşteri',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (customerPhone.isNotEmpty)
                              Text(
                                customerPhone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Cihaz bilgisi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppTheme.categoryIcon(deviceType),
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$deviceType${deviceDetail.isNotEmpty ? ' - $deviceDetail' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isWarranty)
                                const Text(
                                  'Garanti Kapsamında',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.success,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (price > 0)
                          Text(
                            '₺${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Aksiyon butonları
            Row(
              children: [
                _actionButton(
                  icon: Icons.phone,
                  label: 'Ara',
                  color: AppTheme.success,
                  onTap: () => _makePhoneCall(customerPhone),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.message,
                  label: 'Mesaj',
                  color: AppTheme.primaryBlue,
                  onTap: () => _sendSms(customerPhone),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.map,
                  label: 'Konum',
                  color: AppTheme.warning,
                  onTap: () => _openMap(address),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // İşlem Geçmişi
            const Text(
              'İşlem Geçmişi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: statusHistory.isEmpty
                  ? const Text(
                      'Henüz işlem geçmişi yok.',
                      style: TextStyle(color: AppTheme.textGrey),
                    )
                  : Column(
                      children: List.generate(statusHistory.length, (index) {
                        final entry =
                            statusHistory[index] as Map<String, dynamic>;
                        final isLast = index == statusHistory.length - 1;
                        final entryStatus = entry['status'] ?? '';
                        final entryTime = entry['time'] ?? '';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLast
                                        ? AppTheme.statusColor(entryStatus)
                                        : AppTheme.textLight,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: AppTheme.textLight,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entryStatus,
                                      style: TextStyle(
                                        fontWeight: isLast
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isLast
                                            ? AppTheme.statusColor(entryStatus)
                                            : AppTheme.textGrey,
                                      ),
                                    ),
                                    Text(
                                      isLast ? 'Şu An' : entryTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLast
                                            ? AppTheme.statusColor(entryStatus)
                                            : AppTheme.textGrey,
                                        fontWeight: isLast
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 24),

            // Durum güncelleme
            const Text(
              'Durumu Güncelle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((s) {
                final isActive = s == status;
                final color = AppTheme.statusColor(s);
                return GestureDetector(
                  onTap: isActive ? null : () => _updateStatus(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: isActive ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servisi Sil'),
        content: const Text(
          'Bu servis kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('service_records')
                  .doc(widget.ticketId)
                  .delete();
              if (mounted) {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servis silindi.'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}
