import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'services/notification_service.dart';

class AddTicketScreen extends StatefulWidget {
  final String companyName;
  final String? ticketId; // Düzenleme için opsiyonel
  final Map<String, dynamic>? initialData; // Sayfa hızlanması için

  const AddTicketScreen({
    super.key,
    required this.companyName,
    this.ticketId,
    this.initialData,
  });

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _deviceDetailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _assignedToController = TextEditingController();

  String _selectedDeviceType = 'Beyaz Eşya';
  String _selectedPriority = 'Normal';
  bool _isWarranty = false;
  bool _isLoading = false;
  String? _existingTicketNo;

  final List<String> _deviceTypes = [
    'Beyaz Eşya',
    'Klima',
    'TV',
    'Montaj',
    'Bakım',
    'Diğer',
  ];

  final List<String> _priorities = ['Düşük', 'Normal', 'Yüksek', 'Acil'];

  @override
  void initState() {
    super.initState();
    if (widget.ticketId != null) {
      if (widget.initialData != null) {
        _fillData(widget.initialData!);
      } else {
        _fetchAndFillData();
      }
    } else {
      _fetchCurrentUserName();
    }
  }

  Future<void> _fetchCurrentUserName() async {
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
          final userName = userData['name'] ?? user.email?.split('@')[0] ?? '';
          if (mounted) {
            setState(() {
              _assignedToController.text = userName;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı adı çekme hatası: $e');
    }
  }

  void _fillData(Map<String, dynamic> data) {
    _customerNameController.text = data['customerName'] ?? '';
    _customerPhoneController.text = data['customerPhone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _deviceDetailController.text = data['deviceDetail'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = (data['price'] ?? 0).toString();
    _assignedToController.text = data['assignedTo'] ?? '';
    _existingTicketNo = data['ticketNo'];

    if (_deviceTypes.contains(data['deviceType'])) {
      _selectedDeviceType = data['deviceType'];
    }
    if (_priorities.contains(data['priority'])) {
      _selectedPriority = data['priority'];
    }
    _isWarranty = data['isWarranty'] ?? false;
  }

  Future<void> _fetchAndFillData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_records')
          .doc(widget.ticketId)
          .get();
      if (doc.exists) {
        _fillData(doc.data()!);
      }
    } catch (e) {
      debugPrint('Veri çekme hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        final ticketData = {
          'customerName': _customerNameController.text.trim(),
          'customerPhone': _customerPhoneController.text.trim(),
          'address': _addressController.text.trim(),
          'deviceType': _selectedDeviceType,
          'deviceDetail': _deviceDetailController.text.trim(),
          'description': _descriptionController.text.trim(),
          'assignedTo': _assignedToController.text.trim(),
          'priority': _selectedPriority,
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'isWarranty': _isWarranty,
          'updatedAt': Timestamp.fromDate(now),
        };

        if (widget.ticketId == null) {
          // Yeni Kayıt
          final count = await FirebaseFirestore.instance
              .collection('service_records')
              .where('companyName', isEqualTo: widget.companyName)
              .count()
              .get();

          final ticketNo = '#${(count.count! + 1).toString().padLeft(5, '0')}';

          ticketData['ticketNo'] = ticketNo;
          ticketData['companyName'] = widget.companyName;
          ticketData['status'] = 'Bekliyor';
          ticketData['createdAt'] = Timestamp.fromDate(now);
          ticketData['statusHistory'] = [
            {
              'status': 'Talep Alındı',
              'time': timeStr,
              'timestamp': Timestamp.fromDate(now),
            },
          ];

          await FirebaseFirestore.instance
              .collection('service_records')
              .add(ticketData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Servis $ticketNo başarıyla oluşturuldu!'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.of(context).pop();

            // Bildirim tetikle
            NotificationService.showLocalNotificationDirectly(
              'Yeni Servis Kaydı',
              '${ticketData['customerName']} için $ticketNo nolu kayıt oluşturuldu.',
            );
          }
        } else {
          // Düzenleme
          await FirebaseFirestore.instance
              .collection('service_records')
              .doc(widget.ticketId)
              .update(ticketData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servis kaydı güncellendi!'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.of(
              context,
            ).pop(true); // Geri dönerken güncellendi bilgisi ver

            // Bildirim tetikle
            NotificationService.showLocalNotificationDirectly(
              'Servis Güncellendi',
              '${ticketData['customerName']} için kayıt güncellendi.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _addressController.dispose();
    _deviceDetailController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          widget.ticketId == null
              ? 'Yeni Servis Talebi'
              : 'Servis Düzenle ${_existingTicketNo ?? ""}',
        ),
      ),
      body:
          _isLoading &&
              widget.ticketId != null &&
              _customerNameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Müşteri Bilgileri'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Müşteri Adı Soyadı',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Müşteri adı gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customerPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon Numarası',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adres',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Cihaz Bilgileri'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDeviceType,
                      decoration: const InputDecoration(
                        labelText: 'Cihaz Türü',
                        prefixIcon: Icon(Icons.devices_outlined),
                      ),
                      items: _deviceTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDeviceType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deviceDetailController,
                      decoration: const InputDecoration(
                        labelText: 'Cihaz Detayı',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Sorun Açıklaması',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Açıklama gerekli' : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Servis Detayları'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: _priorities.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _assignedToController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Atanan Teknisyen',
                        prefixIcon: Icon(Icons.engineering_outlined),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Ücret (₺)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Garanti Kapsamında'),
                      value: _isWarranty,
                      onChanged: (v) => setState(() => _isWarranty = v),
                      activeThumbColor: AppTheme.success,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTicket,
                        child: Text(
                          widget.ticketId == null ? 'Oluştur' : 'Güncelle',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
