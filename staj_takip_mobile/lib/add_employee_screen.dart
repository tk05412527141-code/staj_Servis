import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String managerCompanyName;

  const AddEmployeeScreen({super.key, required this.managerCompanyName});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Mevcut çalışanlar listesi
  List<Map<String, dynamic>> _employees = [];
  bool _loadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('companyName', isEqualTo: widget.managerCompanyName)
          .get();

      List<Map<String, dynamic>> tempEmployees = [];

      for (var doc in query.docs) {
        final data = doc.data();
        final userId = doc.id;

        // Bu personelin üzerindeki aktif iş sayısını bul
        final ticketQuery = await FirebaseFirestore.instance
            .collection('service_records')
            .where('assignedTo', isEqualTo: userId)
            .where('status', whereIn: ['Bekliyor', 'Atandı', 'Yolda'])
            .get();

        tempEmployees.add({
          'id': userId,
          'name': data['name'] ?? data['email']?.split('@')[0] ?? 'İsimsiz',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'employee',
          'activeCount': ticketQuery.docs.length,
        });
      }

      setState(() {
        _employees = tempEmployees;
        _loadingEmployees = false;
      });
    } catch (e) {
      debugPrint('Çalışan listesi hatası: $e');
      setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _addEmployee() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          for (var doc in querySnapshot.docs) {
            await doc.reference.update({
              'companyName': widget.managerCompanyName,
              'role': 'employee',
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$email" şirkete eklendi!'),
                backgroundColor: AppTheme.success,
              ),
            );
            _emailController.clear();
            _fetchEmployees();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu e-posta ile kayıtlı kullanıcı bulunamadı.'),
                backgroundColor: AppTheme.danger,
              ),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Yönetici';
      case 'admin':
        return 'Admin';
      case 'owner':
        return 'Sahip';
      case 'technician':
        return 'Teknisyen';
      default:
        return 'Çalışan';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(title: const Text('Çalışanlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    widget.managerCompanyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Çalışan ekleme formu
            const Text(
              'Yeni Çalışan Ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Çalışan E-posta Adresi',
                        prefixIcon: Icon(Icons.person_add_outlined),
                        hintText: 'ornek@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'E-posta gerekli';
                        if (!v.contains('@')) return 'Geçerli e-posta girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addEmployee,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Çalışanı Şirkete Ekle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mevcut çalışanlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mevcut Çalışanlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                if (!_loadingEmployees)
                  Text(
                    '${_employees.length} kişi',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loadingEmployees)
              const Center(child: CircularProgressIndicator())
            else if (_employees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Henüz çalışan yok.',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              )
            else
              ...(_employees.map(
                (emp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (emp['name'] as String).isNotEmpty
                              ? (emp['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
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
                              emp['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              emp['email'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _roleLabel(emp['role']),
                          style: const TextStyle(
                            color: AppTheme.accentTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // İş Yükü Göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (emp['activeCount'] as int) > 3
                              ? AppTheme.danger.withValues(alpha: 0.1)
                              : AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${emp['activeCount']} İş',
                          style: TextStyle(
                            color: (emp['activeCount'] as int) > 3
                                ? AppTheme.danger
                                : AppTheme.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
