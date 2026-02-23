import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class AddTicketScreen extends StatefulWidget {
  final String companyName;

  const AddTicketScreen({super.key, required this.companyName});

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

  final List<String> _deviceTypes = [
    'Beyaz Eşya',
    'Klima',
    'TV',
    'Montaj',
    'Bakım',
    'Diğer',
  ];

  final List<String> _priorities = ['Düşük', 'Normal', 'Yüksek', 'Acil'];

  Future<void> _saveTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Ticket numarası oluştur
        final count = await FirebaseFirestore.instance
            .collection('service_records')
            .where('companyName', isEqualTo: widget.companyName)
            .count()
            .get();

        final ticketNo = '#${(count.count! + 1).toString().padLeft(5, '0')}';
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        await FirebaseFirestore.instance.collection('service_records').add({
          'ticketNo': ticketNo,
          'companyName': widget.companyName,
          'status': 'Bekliyor',
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
          'createdAt': Timestamp.fromDate(now),
          'statusHistory': [
            {
              'status': 'Talep Alındı',
              'time': timeStr,
              'timestamp': Timestamp.fromDate(now),
            },
          ],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servis $ticketNo başarıyla oluşturuldu!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Yeni Servis Talebi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Şirket bilgisi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Text(
                      widget.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Müşteri Bilgileri
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
                  hintText: '+90 555 123 45 67',
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

              // Cihaz Bilgileri
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
                onChanged: (v) => setState(() => _selectedDeviceType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deviceDetailController,
                decoration: const InputDecoration(
                  labelText: 'Cihaz Detayı (Marka/Model)',
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Örn: Arçelik Buzdolabı',
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
                    v == null || v.isEmpty ? 'Sorun açıklaması gerekli' : null,
              ),
              const SizedBox(height: 24),

              // Servis Detayları
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
                decoration: const InputDecoration(
                  labelText: 'Atanan Teknisyen',
                  prefixIcon: Icon(Icons.engineering_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Ücret (₺)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              // Garanti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Garanti Kapsamında'),
                  subtitle: Text(
                    _isWarranty ? 'Evet' : 'Hayır',
                    style: TextStyle(
                      color: _isWarranty ? AppTheme.success : AppTheme.textGrey,
                    ),
                  ),
                  value: _isWarranty,
                  onChanged: (v) => setState(() => _isWarranty = v),
                  activeThumbColor: AppTheme.success,
                  secondary: Icon(
                    _isWarranty ? Icons.verified : Icons.cancel_outlined,
                    color: _isWarranty ? AppTheme.success : AppTheme.textGrey,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTicket,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Servis Talebi Oluştur'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }
}
